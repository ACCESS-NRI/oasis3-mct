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
    echo "By default, i.e. without arguments, the source grid is bggd,"
    echo "the target grid is nogt and the remapping is 1st order conservative with SCRIP;"
    echo "1 node, 1 MPI task per node and 1 OpenMP thread per MPI task are used for the run,"
    echo "and no suffixe is used in the rundir name."
    SGRID=bggd ; TGRID=nogt ; remap=conserv1st ; n_p_t=1_1_1 ; nnode=1 ; mpiprocs=1 ; threads=1 ; library=SCRP ; ext=""
elif [ $# -ne 6 ] ; then
    echo "If you don't want to run the default case without arguments, "
    echo "you must run the script with 6 arguments i.e. './run_testinterp.sh src tgt remap nnodes_nprocs_nthreads library ext'"
    echo "where 'src' is the source grid, 'tgt' the target grid and 'remap' the remapping,"
    echo "'nnodes' the total number of nodes for the run, 'nprocs' the number of MPI tasks per node"
    echo "'nthreads' the number of OpenMP threads per MPI task"
    echo "'library' is the regridder used (either SCRP, ESMF or XIOS)"
    echo "'ext' is suffixe is used in the rundir name."
    exit
else
    SGRID=$1 ; TGRID=$2 ; remap=$3 ; n_p_t=$4 ; library=$5 ; ext=$6
    nnode=`echo $n_p_t | awk -F _ '{print $1}'`
    mpiprocs=`echo $n_p_t | awk -F _ '{print $2}'`
    threads=`echo $n_p_t | awk -F _ '{print $3}'`
fi
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
if [ ${SGRID} == "bggd" ] && [ ${SGRID} == "sse7" ] && [ ${SGRID} == "icos" ] && [ ${SGRID} == "icoh" ]; then
    if [ ${TGRID} != "nogt" ] && [ ${TGRID} != "torc" ]; then
	echo "You have to match an atmospheric grid (bggd, sse7, icos or icoh) with an ocean grid (nogt, torc)"
	exit
    fi
fi	
if [ ${TGRID} == "bggd" ] && [ ${TGRID} == "sse7" ] && [ ${TGRID} == "icos" ] && [ ${TGRID} == "icoh" ]; then
    if [ ${SGRID} != "nogt" ] && [ ${SGRID} != "torc" ]; then
	echo "You have to match an an ocean grid (nogt, torc) with an atmospheric grid (bggd, sse7, icos or icoh)" 
	exit
    fi
fi

## - Check remap
## distwgt (nearest-neighbour), bili (bilinear), bicu (bicubic), conserv1st or conserv2nd (1st or 2nd order conservative remapping)
if [ ${remap} != "distwgt" ] && [ ${remap} != "bili" ] && [ ${remap} != "bicu" ] && [ ${remap} != "conserv1st" ] && [ ${remap} != "conserv2nd" ]; then
    echo "Remapping must be either distwgt, bili, bicu, conserv1st, conserv2nd"
    exit
fi

## - Check library
if [ ${library} != "SCRP" ] && [ ${library} != "ESMF" ] && [ ${library} != "XIOS" ]; then
    echo "Remapping library must be either SCRP (for SCRIP), ESMF or XIOS"
    exit
fi

## - Check source grid type and remapping for SCRP (no conserv2nd for sse7 ; no bili, bicu, conserv2nd for icos)
if [ ${library} == "SCRP" ]; then
    if [ ${SGRID} == "sse7" ]; then
	if [ ${remap} == "conserv2nd" ]; then
	    echo "Impossible to perform conserv2nd remapping from gaussian reduced grid sse7"
	    exit
	fi
    elif [ ${SGRID} == "icos" ] || [ ${SGRID} == "icoh" ]; then
	if [ ${remap} == "conserv2nd" ] || [ ${remap} == "bicu" ] || [ ${remap} == "bili" ]; then
	    echo "Impossible to perform ${remap} remapping from unstructured grid icos"
	    exit
	fi
    fi
fi

## - Only 1st and 2nd order conservative remapping for XIOS
if [ ${library} == "XIOS" ]; then
    if [ ${remap} == "conserv1st" ]; then
	xiosmethod=CONSERV_FRACAREA
	order=1
    elif [ ${remap} == "conserv2nd" ]; then
	xiosmethod=CONS2ND_FRACAREA
	order=2
    else
	echo "XIOS does not support ${remap} remapping "
	exit
    fi
fi    
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
rundir=$srcdir/RUNDIR_${library}_${ext}/${casename}_${SGRID}_${TGRID}_${remap}_${nnode}_${mpiprocs}_${threads}_${library}_${ext}
\rm -fr $rundir/* ; mkdir -p $rundir

## - Create namcouple
./namcouple_create.sh ${SGRID} ${TGRID} ${remap} ${n_p_t} ${library} ${ext}

## - Name of the executables
exe1=model1
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

### - Define mask name which depends on ocean grid
if [ ${SGRID} == "nogt" ] || [ ${TGRID} == "nogt" ]; then
    maskname=$oasisdir/${library}_masks/masks_nogt_${library}.nc
elif [ ${SGRID} == "torc" ] || [ ${TGRID} == "torc" ]; then
    maskname=$oasisdir/${library}_masks/masks_torc_${library}.nc
fi

###
if [ ${library} == "ESMF" ]; then
    ## With ESMF, nogt should be transformed to an unstructured grid 
    OasisGridsToESMF="OasisGridsToESMF.py"
    if [ ${SGRID} == "nogt" ]; then
        if [ ${remap} == "conserv1st" ] || [ ${remap} == "conserv2nd" ]; then
            OasisGridsToESMF="OasisGridsToESMF_nogtunstruct.py"
        fi
    fi
    cp -f $esmfdir/$OasisGridsToESMF  $rundir/.
    cp -f $esmfdir/ESMFWeightsToOasis.sh  $rundir/.
    ### Define regridding options
    case $remap in
	bili)             meth_esmfname="bilinear" ; options="--extrap_method neareststod --src_loc center --dst_loc center" ;;
	bicu)             meth_esmfname="patch" ; options="--extrap_method neareststod --src_loc center --dst_loc center" ;;
	distwgt)          meth_esmfname="neareststod" ; options="--extrap_method neareststod --src_loc center --dst_loc center" ;;
	conserv1st)       meth_esmfname="conserve" ; options="--ignore_unmapped --norm_type fracarea" ;;
	conserv2nd)      meth_esmfname="conserve2nd" ; options="--ignore_unmapped --norm_type fracarea" ;;
	*)  echo "Method $remap unknown in ESMF."
	    exit ;;
    esac      
## 
elif [ ${library} == "XIOS" ]; then
    exexios=oasis_testcase.exe    
    cat <<EOF > param.def
&params_run
nb_proc_toy=$nproces
/
EOF
    cp -f param.def $rundir/param.def
    cat <<EOF > sed.sh
#!/bin/ksh
sed -e 's:SGRID:$SGRID:' -e 's:TGRID:$TGRID:' -e 's:GRIDS:$rundir/grids.nc:' -e 's:MASKS:$rundir/masks.nc:' $xiosdir/iodef.xml_template > ${rundir}/iodef.xml
sed -e 's:ORDER:$order:' $xiosdir/context_toy.xml_template > ${rundir}/context_toy.xml
EOF
    chmod u+x sed.sh
    ./sed.sh
    cp -f $xiosdir/$exexios $rundir/$exexios
    #
fi

### - Link everything needed into rundir
ln -sf $oasisdir/grids.nc $rundir/grids.nc
ln -sf ${maskname} $rundir/masks.nc
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
    timreq=00:30:00
    if [ ${library} == "SCRP" ]; then
	cat <<EOF > $rundir/run_$casename.$arch
#!/bin/bash -l
#Partition
#SBATCH --partition prod
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

cd $rundir

export KMP_STACKSIZE=1GB
export I_MPI_PIN_DOMAIN=omp
export I_MPI_WAIT_MODE=enable
export KMP_AFFINITY=verbose,granularity=fine,compact
export OASIS_OMP_NUM_THREADS=$threads

time mpirun -np $nproces ./$exe1
EOF
      
    elif [ ${library} == "ESMF" ]; then
	

  cat <<EOF > $rundir/run_$casename.$arch
#!/bin/bash -l
#Partition
#SBATCH --partition prod
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
# Number of OpenMP threads per MPI task
#SBATCH --cpus-per-task=$threads

cd $rundir

export KMP_STACKSIZE=1GB
export I_MPI_PIN_DOMAIN=omp
export I_MPI_WAIT_MODE=enable
export KMP_AFFINITY=verbose,granularity=fine,compact
export OMP_NUM_THREADS=$threads

python ./$OasisGridsToESMF $SGRID $rundir
python ./$OasisGridsToESMF $TGRID $rundir
# Generate ESMF weights
time mpirun -np $nproces ESMF_RegridWeightGen -s ${SGRID}_ESMF.nc -d ${TGRID}_ESMF.nc -m ${meth_esmfname} -w ESMFweights.nc --ignore_degenerate ${options}

# Convert ESMF weight file in OASIS format
./ESMFWeightsToOasis.sh ${SGRID} ${TGRID} ${remap}

time mpirun -np $nproces ./$exe1
EOF
    elif [ ${library} == "XIOS" ]; then
  cat <<EOF > $rundir/run_$casename.$arch
#!/bin/bash -l
#Partition
#SBATCH --partition prod
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
    if [ ${library} == "SCRP" ]; then   
  cat <<EOF > $rundir/run_$casename.$arch
#!/bin/bash
#SBATCH --exclusive
#SBATCH --partition=normal256
#SBATCH --job-name ${remap}_${nthreads}
#SBATCH --time=02:00:00
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
export OASIS_OMP_NUM_THREADS=$threads
export OMP_NUM_THREADS=$threads
#
time mpirun -np ${nproces} ./$exe1
#
EOF

    elif [ ${library} == "ESMF" ]; then
	  cat <<EOF > $rundir/run_$casename.$arch
#!/bin/bash -l
#SBATCH --exclusive
#SBATCH --partition=normal256
#SBATCH --job-name ${remap}_${nthreads}
#SBATCH --time=02:00:00
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

python ./$OasisGridsToESMF $SGRID $rundir
python ./$OasisGridsToESMF $TGRID $rundir
# Generate ESMF weights
time mpirun -np $nproces ESMF_RegridWeightGen -s ${SGRID}_ESMF.nc -d ${TGRID}_ESMF.nc -m ${meth_esmfname} -w ESMFweights.nc --ignore_degenerate ${options}

# Convert ESMF weight file in OASIS format
./ESMFWeightsToOasis.sh ${SGRID} ${TGRID} ${remap}

time mpirun -np $nproces ./$exe1
EOF
	  
    elif [ ${library} == "XIOS" ]; then
	cat <<EOF > $rundir/run_$casename.$arch
#!/bin/bash -l
#SBATCH --exclusive
#SBATCH --partition=normal256
#SBATCH --job-name ${remap}_${nthreads}
#SBATCH --time=02:00:00
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
# Generate XIOS weights
time mpirun -np $nproces ./$exexios 
# Convert ESMF weight file in OASIS format
python $srcdir/XIOS/XiosWeightsToOasis.py
ln -sf rmp_${SGRID}_to_${TGRID}_xios_${xiosmethod}.nc rmp_${SGRID}_${TGRID}.nc
#
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

