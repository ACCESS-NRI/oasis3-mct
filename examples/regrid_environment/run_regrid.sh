#!/bin/ksh
#set -x

host=`uname -n`
user=`whoami`

## - User's choice of computing architecture
arch=kraken_intel_impi_openmp  # kraken_intel_impi_openmp, belenos

## - Define paths
srcdir=`pwd`
oasisdir=$srcdir/OASIS
xiosdir=$srcdir/XIOS
esmfdir=$srcdir/ESMF
casename=`basename $srcdir`

## - Define case
if [ $# -eq 0 ] ; then
    echo -e "\nBy default, i.e. without arguments, the source grid is bggd,"
    echo "the target grid is nogt and the remapping is 1st order conservative fracarea with SCRIP;"
    echo "the interpolated analytical function is sinusoid;"
    echo "1 node, 1 MPI task per node and 1 OpenMP thread per MPI task are used for the run,"
    echo -e "and no suffixe is used in the rundir name.\n"
    SGRID=bggd ; TGRID=nogt ; remap=conserv_1st_fracarea ; fana=sinusoid ; n_p_t=1_1_1 ; library=SCRP ; ext=""
elif [ $# -ne 7 ] ; then
    echo -e "\nIf you don't want to run the default case without arguments, "
    echo "you must run the script with 7 arguments i.e. './run_regrid.sh src tgt remap fana nnodes_nprocs_nthreads library ext'"
    echo "where 'src' is the source grid, 'tgt' the target grid, 'remap' the remapping and 'fana' the analytical function"
    echo "'nnodes' the total number of nodes for the run, 'nprocs' the number of MPI tasks per node"
    echo "'nthreads' the number of OpenMP threads per MPI task"
    echo "'library' is the regridder used (either SCRP, ESMF or XIOS)"
    echo "'ext' is suffixe used in the rundir name."
    echo -e "Example: ./run_regrid.sh icos torc conserv_1st_fracarea gulfstream 1_2_18 SCRP A\n"
    exit
else
    SGRID=$1 ; TGRID=$2 ; remap=$3 ; fana=$4 ; n_p_t=$5 ; library=$6 ; ext=$7
fi

method=`echo $remap | awk -F _ '{print $1}'`
order=`echo $remap | awk -F _ '{print $2}'`
normalization=`echo $remap | awk -F _ '{print $3}'`

nnode=`echo $n_p_t | awk -F _ '{print $1}'`
mpiprocs=`echo $n_p_t | awk -F _ '{print $2}'`
threads=`echo $n_p_t | awk -F _ '{print $3}'`
nproces=`echo $(($nnode*$mpiprocs))`

## - Check grids
## bggd is an atmosphere structured (LR) grid ; sse7 is an atmosphere gaussian reduced (D) grid
## icos/icoh is an atmosphere unstructured (U) grid ; nogt/torc is an ocean structured (LR) grid
if [ ${SGRID} != "bggd" ] && [ ${SGRID} != "sse7" ] && [ ${SGRID} != "icos" ] && [ ${SGRID} != "icoh" ] && [ ${SGRID} != "nogt" ] && [ ${SGRID} != "torc" ]; then
    echo "Source grid must be either bggd, sse7, icos, icoh, nogt or torc"
    exit
fi
if [ ${TGRID} != "bggd" ] && [ ${TGRID} != "sse7" ] && [ ${TGRID} != "icos" ] && [ ${TGRID} != "icoh" ] && [ ${TGRID} != "nogt" ] && [ ${TGRID} != "torc" ]; then
    echo "Target grid must be either bggd, sse7, icos, icoh, nogt, torc"
    exit
fi
if [ ${SGRID} == "bggd" ] || [ ${SGRID} == "sse7" ] || [ ${SGRID} == "icos" ] || [ ${SGRID} == "icoh" ]; then
    if [ ${TGRID} != "nogt" ] && [ ${TGRID} != "torc" ]; then
	echo "You have to match an atmospheric grid (bggd, sse7, icos or icoh) with an ocean grid (nogt, torc)"
	exit
    fi
fi	
if [ ${SGRID} == "nogt" ] || [ ${SGRID} == "torc" ]; then
    if [ ${TGRID} != "bggd" ] && [ ${TGRID} != "sse7" ] && [ ${TGRID} != "icos" ] && [ ${TGRID} != "icoh" ]; then
	echo "You have to match an an ocean grid (nogt, torc) with an atmospheric grid (bggd, sse7, icos or icoh)" 
	exit
    fi
fi

## - Check remap
## distwgt (nearest-neighbour), bili (bilinear), bicu (bicubic), conserv1st or conserv2nd (1st or 2nd order conservative remapping)
if [ ${remap} != "distwgt" ] && [ ${remap} != "bili" ] && [ ${remap} != "bicu" ] && [ ${remap} != "conserv_1st_fracarea" ] && [ ${remap} != "conserv_2nd_fracarea" ] && [ ${remap} != "conserv_1st_destarea" ] && [ ${remap} != "conserv_2nd_destarea" ]; then
    echo "Remapping must be either distwgt, bili, bicu, conserv_1st_fracarea, conserv_2nd_fracarea, conserv_1st_destarea, conserv_2nd_destarea"
    exit
fi

## - Check fana
if [ ${fana} != "sinusoid" ] && [ ${fana} != "vortex" ] && [ ${fana} != "gulfstream" ] && [ ${fana} != "harmonic" ] && [ ${fana} != "mask" ]; then
    echo "Analytical function must be either sinusoid, gulfstream, vortex, harmonic"
    exit
fi

## - Check library
if [ ${library} != "SCRP" ] && [ ${library} != "ESMF" ] && [ ${library} != "XIOS" ]; then
    echo -e "\nRemapping library must be either SCRP (for SCRIP), ESMF or XIOS\n"
    exit
fi

## - Check source grid type and remapping for SCRP (no conserv2nd for sse7 ; no bili, bicu, conserv2nd for icos)
if [ ${library} == "SCRP" ]; then
    if [ ${SGRID} == "sse7" ]; then
	if [[ ${remap} == "conserv_2nd"* ]]; then
	    echo "Impossible to perform conserv_2nd remapping from gaussian reduced grid sse7"
	    exit
	fi
    elif [ ${SGRID} == "icos" ] || [ ${SGRID} == "icoh" ]; then
	if [[ ${remap} == "conserv_2nd"* ]] || [[ ${remap} == "bicu" ]] || [[ ${remap} == "bili" ]]; then
	    echo "Impossible to perform ${remap} remapping from unstructured grid icos"
	    exit
	fi
    fi
fi

## - Only 1st and 2nd order conservative remapping for XIOS
if [ ${library} == "XIOS" ]; then
    if [ ${method} == "conserv" ]; then
        case $normalization in
            fracarea) xiosrenormalize=true ;;
            destarea) xiosrenormalize=false ;;
        esac
        xiosnorm=`echo ${normalization} | tr '[:lower:]' '[:upper:]'`
        case $order in
                1st) xiosmethod=CONSERV_${xiosnorm} ;;
                2nd) xiosmethod=CONS2ND_${xiosnorm} ;;
        esac
        xiosorder=${order:0:1}
    else
        echo "XIOS does not support ${method} remapping "
        exit
    fi
fi    

## - Compilation if the analytical function has changed compared to the CPP key or if executable model1 does not exist 
exe1=model1
cd $srcdir/src
grep "^CPPKEY_FANA=F$fana" Makefile > /dev/null
if [ $? != 0 ]; then
    echo "Compiling model1 as CPP key in Makefile is not the one corresponding to the analytical function chosen" 
    sed -i "s/^CPPKEY_FANA=.*/CPPKEY_FANA=F$fana/" Makefile
    make
else
    if [[ -e ${exe1} ]]; then
       echo "Not compiling model1 as it exists and CPP key in Makefile corresponds to the analytical function chosen" 
    else
       echo "Compiling model1 even if CPP key in Makefile corresponds to the analytical function chosen as model1 does not exist"
       make
    fi
fi
cd $srcdir

## - Source grid characteristics 
if [ ${SGRID} == bggd ]; then
    STYPE=LR ; SRCP=P ; SRCPN=0   
elif [ ${SGRID} == sse7 ]; then
    STYPE=D ; SRCP=P ; SRCPN=0
elif [ ${SGRID} == icos ] || [ ${SGRID} == icoh ]; then
    STYPE=U ; SRCP=P ; SRCPN=0
elif [ ${SGRID} == nogt ] || [ ${SGRID} == torc ]; then
    STYPE=LR ; SRCP=P ; SRCPN=2
fi
## - Target grid characteristics 
if [ ${TGRID} == bggd ]; then
    TTYPE=LR ; TGTP=P
elif [ ${TGRID} == sse7 ]; then
    TTYPE=D ; TGTP=P
elif [ ${TGRID} == icos ] || [ ${TGRID} == icoh ]; then
    TTYPE=U ; TGTP=P
elif [ ${TGRID} == nogt ] || [ ${TGRID} == torc ]; then
    TTYPE=LR ; TGTP=P
fi

## - rundir definition
rundir=$srcdir/RUNDIR_${library}_${ext}/${casename}_${SGRID}_${TGRID}_${remap}_${fana}_${n_p_t}_${library}_${ext}
\rm -fr $rundir/* ; mkdir -p $rundir

## - Create namcouple
./namcouple_create.sh ${SGRID} ${TGRID} ${remap} ${fana} ${n_p_t} ${library} ${ext}
##
echo ''
echo '**************************************************************************************************************'
echo '*** '$casename' : '$run
echo ''
echo "Running test_interpolation on $nnode nodes with $mpiprocs MPI tasks per node and $threads threads per MPI task"
echo '**************************************************************************************************************'
echo 'Source grid :' $SGRID
echo 'Target grid :' $TGRID
echo 'Rundir       :' $rundir
echo 'Architecture :' $arch
echo 'Host         : '$host
echo 'User         : '$user
echo 'Grids        : '$SGRID'-->'$TGRID
echo 'Remap        : '$remap
echo 'Remapping library: '$library
echo ''
echo $exe1' runs on '$nproces 'processes'
echo ''

## - Define mask name which depends on ocean grid 
if [ ${SGRID} == "nogt" ] || [ ${TGRID} == "nogt" ]; then
    maskname=$oasisdir/${library}_masks/masks_nogt_${library}.nc
elif [ ${SGRID} == "torc" ] || [ ${TGRID} == "torc" ]; then
    maskname=$oasisdir/${library}_masks/masks_torc_${library}.nc
fi
## - If the script is used by run_createMasks.sh to create an atmospheric mask
if [ ${fana} == "mask" ]; then
    maskname=$oasisdir/masks_no_atm.nc # blank atmospheric masks
fi

##
if [ ${library} == "ESMF" ]; then
    # Knowing if the source grid is unstructured 
    if [ ${STYPE} = "LR" ]; then
        sgridIsUnstruct="False"
    else
        sgridIsUnstruct="True"
    fi
    # With the current ESMF, nogt should be transformed to an unstructured grid for conservative methods
    if [ ${SGRID} == "nogt" ] && [ ${method} == "conserv" ]; then
        sgridIsUnstruct="True"
    fi
    # Knowing if the target grid is unstructured 
    if [ ${TTYPE} = "LR" ]; then
        tgridIsUnstruct="False"
    else
        tgridIsUnstruct="True"
    fi
    cp -f $esmfdir/OasisGridsToESMF.py  $rundir/.
    cp -f $esmfdir/ESMFWeightsToOasis.sh  $rundir/.
    ### Define regridding options
    case $method in
        bili)             esmfmethod="bilinear" ; options="--extrap_method neareststod --src_loc center --dst_loc center" ;;
        bicu)             esmfmethod="patch" ; options="--extrap_method neareststod --src_loc center --dst_loc center" ;;
        distwgt)          esmfmethod="neareststod" ; options="--extrap_method neareststod --src_loc center --dst_loc center" ;;
        conserv)
            case $order in
                1st) esmfmethod="conserve" ;;
                2nd) esmfmethod="conserve2nd" ;;
            esac
            case $normalization in
                fracarea) options="--ignore_unmapped --norm_type fracarea" ;;
                destarea) options="--ignore_unmapped" ;; # in ESMF default normalization is destarea
            esac
            ;;
        *)  echo "Method $method unknown in ESMF." ; exit ;;
    esac
## 
elif [ ${library} == "XIOS" ]; then
    exexios=oasis_testcase.exe    
    cat <<EOF > $rundir/param.def
&params_run
nb_proc_toy=$nproces
/
EOF
    sed "s#SGRID#$SGRID#; s#TGRID#$TGRID#; s#GRIDS#$rundir/grids.nc#; s#MASKS#$rundir/masks.nc#" $xiosdir/iodef.xml_template > ${rundir}/iodef.xml
    sed "s#ORDER#$xiosorder#; s#RENORMALIZE#$xiosrenormalize#" $xiosdir/context_toy.xml_template > ${rundir}/context_toy.xml
    cp -f $xiosdir/$exexios $rundir/.
fi

## - Link everything needed into rundir
cd $rundir
curl -O https://mercure.cerfacs.fr/oasis3-mct/examples/regrid_environment/OASIS/grids.nc
ln -sf ${maskname} ./masks.nc
ln -sf $srcdir/src/$exe1 $rundir/.

## - Create name_grids.dat, that will be read by the models, from namcouple informations
cat <<EOF >> $rundir/name_grids.dat
\$grid_source_characteristics
cl_grd_src='$SGRID'
cl_remap='$remap'
cl_type_src='$STYPE'
cl_period_src='$SRCP'
il_overlap_src=$SRCPN
\$end
\$grid_target_characteristics
cl_grd_tgt='$TGRID'
cl_type_tgt='$TTYPE'
\$end
\$remapper
cl_library='$library'
\$end
EOF
#
cd $rundir

######################################################################
## - Creation of batch job  scripts

###---------------------------------------------------------------------
### KRAKEN_INTEL_IMPI_OPENMP 
###---------------------------------------------------------------------
if [ ${arch} == kraken_intel_impi_openmp ]; then
    queue=prodshared
    timreq=00:10:00
    cat <<EOF > $rundir/run_$casename.$arch
#!/bin/bash -l
#Partition
#SBATCH --partition=$queue
# Nom du job
#SBATCH --job-name ${n_p_t}
# Time limit for the job
#SBATCH --time=$timreq
#SBATCH --output=$rundir/$casename.o
#SBATCH --error=$rundir/$casename.e
# Number of nodes
#SBATCH --nodes=$nnode
# Number of MPI tasks per node
#SBATCH --ntasks-per-node=$mpiprocs
EOF

    if [ ${library} == "SCRP" ]; then
	cat <<EOF >> $rundir/run_$casename.$arch

cd $rundir

export KMP_STACKSIZE=1GB
export I_MPI_PIN_DOMAIN=omp
export I_MPI_WAIT_MODE=enable
export KMP_AFFINITY=verbose,granularity=fine,compact
export OASIS_OMP_NUM_THREADS=$threads

time mpirun -np $nproces ./$exe1
EOF
      
    elif [ ${library} == "ESMF" ]; then
        cat <<EOF >> $rundir/run_$casename.$arch
# Number of OpenMP threads per MPI task
#SBATCH --cpus-per-task=$threads

cd $rundir

export KMP_STACKSIZE=1GB
export I_MPI_PIN_DOMAIN=omp
export I_MPI_WAIT_MODE=enable
export KMP_AFFINITY=verbose,granularity=fine,compact
export OMP_NUM_THREADS=$threads

python ./OasisGridsToESMF.py $SGRID $rundir $sgridIsUnstruct
python ./OasisGridsToESMF.py $TGRID $rundir $tgridIsUnstruct
# Generate ESMF weights
time mpirun -np $nproces ESMF_RegridWeightGen -s ${SGRID}_ESMF.nc -d ${TGRID}_ESMF.nc -m ${esmfmethod} -w ESMFweights.nc --ignore_degenerate ${options}

# Convert ESMF weight file in OASIS format
./ESMFWeightsToOasis.sh ${SGRID} ${TGRID} ${esmfmethod}_${normalization}

time mpirun -np $nproces ./$exe1
EOF

    elif [ ${library} == "XIOS" ]; then
        cat <<EOF >> $rundir/run_$casename.$arch
# Number of OpenMP threads per MPI task
#SBATCH --cpus-per-task=$threads

cd $rundir

export KMP_STACKSIZE=1GB
export I_MPI_PIN_DOMAIN=omp
export I_MPI_WAIT_MODE=enable
export KMP_AFFINITY=verbose,granularity=fine,compact
export OMP_NUM_THREADS=$threads

# Generate XIOS weights
time mpirun -np $nproces ./$exexios 
# Convert XIOS weight file in OASIS format
python $srcdir/XIOS/XiosWeightsToOasis.py
ln -sf rmp_${SGRID}_to_${TGRID}_xios_${xiosmethod}.nc rmp_${SGRID}_${TGRID}.nc
#
time mpirun -np $nproces ./$exe1
EOF
    fi


elif [ $arch == belenos ] ; then
    timreq=02:00:00
    cat <<EOF > $rundir/run_$casename.$arch
#!/bin/bash
#SBATCH --exclusive
#SBATCH --partition=normal256
#SBATCH --job-name ${remap}_${nthreads}
#SBATCH --time=$timreq
#SBATCH -o $rundir/$casename.o
#SBATCH -e $rundir/$casename.e
#SBATCH -N $nnode
#SBATCH --ntasks-per-node=$mpiprocs
#
ulimit -s unlimited
cd $rundir
#
export KMP_STACKSIZE=1GB
export I_MPI_WAIT_MODE=enable
export KMP_AFFINITY=verbose,granularity=fine,compact
#
EOF

    if [ ${library} == "SCRP" ]; then   
        cat <<EOF >> $rundir/run_$casename.$arch
export OASIS_OMP_NUM_THREADS=$threads
export OMP_NUM_THREADS=$threads
#
time mpirun -np ${nproces} ./$exe1
#
EOF

    elif [ ${library} == "ESMF" ]; then
	cat <<EOF >> $rundir/run_$casename.$arch
# Convert OASIS grid file in ESMF format
python ./OasisGridsToESMF.py $SGRID $rundir $sgridIsUnstruct
python ./OasisGridsToESMF.py $TGRID $rundir $tgridIsUnstruct

# Generate ESMF weights
time mpirun -np $nproces ESMF_RegridWeightGen -s ${SGRID}_ESMF.nc -d ${TGRID}_ESMF.nc -m ${esmfmethod} -w ESMFweights.nc --ignore_degenerate ${options}

# Convert ESMF weight file in OASIS format
./ESMFWeightsToOasis.sh ${SGRID} ${TGRID} ${esmfmethod}_${normalization}

time mpirun -np $nproces ./$exe1
EOF
	  
    elif [ ${library} == "XIOS" ]; then
        cat <<EOF >> $rundir/run_$casename.$arch
# Generate XIOS weights
time mpirun -np $nproces ./$exexios 

# Convert XIOS weight file in OASIS format
python $srcdir/XIOS/XiosWeightsToOasis.py
ln -sf rmp_${SGRID}_to_${TGRID}_xios_${xiosmethod}.nc rmp_${SGRID}_${TGRID}.nc

time mpirun -np $nproces ./$exe1
EOF
    fi
fi

######################################################################
### - Execute the model

if [ $arch == kraken_intel_impi_openmp ]; then
    echo 'Submitting the job to queue using sbatch'
    sbatch $rundir/run_$casename.$arch
    squeue -u $USER
elif [ $arch == belenos ]; then
    echo 'Submitting the job to queue using sbatch'
    sbatch $rundir/run_$casename.$arch
    squeue -u $user
fi

echo $casename 'is executed or submitted to queue.'
echo 'Results are found in rundir : '$rundir 

######################################################################

