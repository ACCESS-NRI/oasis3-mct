#!/bin/ksh
#set -x

host=`uname -n`
user=`whoami`

## - Define paths
srcdir=`pwd`
datadir=$srcdir/data_oasis
casename=`basename $srcdir`

## - Define case
if [ $# -eq 0 ] ; then
    echo "By default, i.e. without arguments, the source grid is bggd,"
    echo "the target grid is nogt and the remapping is 1st order conservative with SCRIP;"
    echo "1 node, 1 MPI task per node and 1 OpenMP thread per MPI task are used for the run,"
    echo "and no suffixe is used in the rundir name."
    SRC_GRID=bggd
    TGT_GRID=nogt
    remap=conserv1st
    n_p_t=1_1_1
    nnode=1
    mpiprocs=1
    threads=1
    library=SCRIP
    ext=""
elif [ $# -ne 6 ] ; then
    echo "If you don't want to run the default case without arguments, "
    echo "you must run the script with 6 arguments i.e. './run_testinterp.sh src tgt remap nnodes_nprocs_nthreads library ext'"
    echo "where 'src' is the source grid, 'tgt' the target grid and 'remap' the remapping,"
    echo "'nnodes' the total number of nodes for the run, 'nprocs' the number of MPI tasks per node"
    echo "'nthreads' the number of OpenMP threads per MPI task"
    echo "'library' is the regridder used (either SCRIP, ESMF or XIOS)"
    echo "'ext' is suffixe is used in the rundir name."
    exit
else
    SRC_GRID=$1
    TGT_GRID=$2
    remap=$3
    n_p_t=$4
    nnode=`echo $n_p_t | awk -F _ '{print $1}'`
    mpiprocs=`echo $n_p_t | awk -F _ '{print $2}'`
    threads=`echo $n_p_t | awk -F _ '{print $3}'`
    library=$5
    ext=$6
fi
##
nproces=`echo $(($nnode*$mpiprocs))`
##
## User's choice of computing architecture
#SVSV: verifier les architectures et simplifier
arch=kraken_intel_impi_openmp  # nemo_lenovo_intel_impi_openmp, kraken_intel_impi_openmp,
          # training_computer, gfortran_openmpi_openmp_linux, belenos, mac
	  # pgi_openmpi_openmp_linux, 
	  # pgi20.4_openmpi_openmp_linux (not work with 4.0)
	  # gnu1020_openmpi_openmp_linux (not work with 4.0)
##
######################################################################
##
## - Grids
## bggd is an atmosphere structured (LR) grid
## ssea is an atmosphere gaussian reduced (D) grid
## icos/icoh is an atmosphere unstructured (U) grid
## nogt/t12e is an ocean structured (LR) grid
##
## - Remapping : distwgt (nearest-neighbour), bili (bilinear), bicu (bicubic), conserv1st or conserv2nd (1st or 2nd order conservative remapping)
##
## - Verification source grid type and remapping for SCRIP (no conserv2nd for ssea ; no bili, bicu, conserv2nd for icos)
if [ ${library} == "SCRIP" ]; then
    if [ ${SRC_GRID} == "ssea" ]; then
	if [ ${remap} == "conserv2nd" ]; then
	    echo "Impossible to perform conserv2nd remapping from gaussian reduced grid ssea"
	    exit
	fi
    fi
    if [ ${SRC_GRID} == "icos" ] || [ ${SRC_GRID} == "icoh" ]; then
	if [ ${remap} == "conserv2nd" ] || [ ${remap} == "bicu" ] || [ ${remap} == "bili" ]; then
	    echo "Impossible to perform ${remap} remapping from unstructured grid icos"
	    exit
	fi
    fi
fi
##
## If nogt is source grid and remap is bili, bicu or distwgt, not shoul not be transformed in an unstructured grid
OasisGridsToESMF=OasisGridsToESMF.py
if [ ${library} == "ESMF" ]; then
    if [ ${SRC_GRID} == "nogt" ]; then
        if [ ${remap} == "conserv1st" ] || [ ${remap} == "conserv2nd" ] ; then
            OasisGridsToESMF=OasisGridsToESMF_nogtunstruct.py
        fi
    fi
fi
OasisGridsToESMF=OasisGridsToESMF_nogtunstruct.py
echo $OasisGridsToESMF
##
rundir=$srcdir/RUNDIR_${ext}/${casename}_${SRC_GRID}_${TGT_GRID}_${remap}_${nnode}_${mpiprocs}_${threads}_${library}_${ext}
##
######################################################################
##
## - Name of the executables
exe1=model1
##
echo ''
echo '**************************************************************************************************************'
echo '*** '$casename' : '$run
echo ''
echo "Running test_interpolation on $nnode nodes with $mpiprocs MPI tasks per node and $threads threads per MPI task"
echo '**************************************************************************************************************'
echo 'Source grid :' $SRC_GRID
echo 'Target grid :' $TGT_GRID
echo 'Rundir       :' $rundir
echo 'Architecture :' $arch
echo 'Host         : '$host
echo 'User         : '$user
echo 'Grids        : '$SRC_GRID'-->'$TGT_GRID
echo 'Remap        : '$remap
echo ''
echo $exe1' runs on '$nproces 'processes'
echo ''
echo ''

## - Copy everything needed into rundir
\rm -fr $rundir/*
mkdir -p $rundir
##
ln -sf $datadir/grids.nc  $rundir/grids.nc
ln -sf $datadir/masks.nc  $rundir/masks.nc
#ln -sf $datadir/areas.nc  $rundir/areas.nc
ln -sf $srcdir/$exe1 $rundir/.
if [ ${library} == "SCRIP" ]; then
    cp -f $datadir/namcouple_${SRC_GRID}_${TGT_GRID}_${remap} $rundir/namcouple
elif [ ${library} == "ESMF" ]; then
    cp -f $datadir/namcouple_${SRC_GRID}_${TGT_GRID}_esmf $rundir/namcouple
fi

## - Grid source characteristics 
if [ ${SRC_GRID} == bggd ]; then
    SRC_GRID_TYPE=LR
    SRC_GRID_PERIOD=P
    SRC_GRID_OVERLAP=0   
elif [ ${SRC_GRID} == ssea ]; then
    SRC_GRID_TYPE=D
    SRC_GRID_PERIOD=P
    SRC_GRID_OVERLAP=0
elif [ ${SRC_GRID} == icos ] || [ ${SRC_GRID} == "icoh" ]; then
    SRC_GRID_TYPE=U
    SRC_GRID_PERIOD=P
    SRC_GRID_OVERLAP=0
elif [ ${SRC_GRID} == nogt ] || [ ${SRC_GRID} == "t12e" ]; then
    SRC_GRID_TYPE=LR
    SRC_GRID_PERIOD=P
    SRC_GRID_OVERLAP=2
fi
if [ ${TGT_GRID} == bggd ]; then
    TGT_GRID_TYPE=LR  
elif [ ${TGT_GRID} == ssea ]; then
    TGT_GRID_TYPE=D
elif [ ${TGT_GRID} == icos ]; then
    TGT_GRID_TYPE=U
elif [ ${TGT_GRID} == nogt ] || [ ${SRC_GRID} == "t12e" ]; then
    TGT_GRID_TYPE=LR
fi

## - Create name_grids.dat, that will be read by the models, from namcouple informations
cat <<EOF >> $rundir/name_grids.dat
\$grid_source_characteristics
cl_grd_src='$SRC_GRID'
cl_remap='$remap'
cl_type_src='$SRC_GRID_TYPE'
cl_period_src='$SRC_GRID_PERIOD'
il_overlap_src=$SRC_GRID_OVERLAP
\$end
\$grid_target_characteristics
cl_grd_tgt='$TGT_GRID'
cl_type_tgt='$TGT_GRID_TYPE'
\$end
EOF
#
cd $rundir

######################################################################
## - Creation of configuration scripts

###---------------------------------------------------------------------
### NEMO_LENOVO_INTEL_IMPI_OPENMP
###---------------------------------------------------------------------
if [ ${arch} == nemo_lenovo_intel_impi_openmp ]; then
#SVSV a adpater a ESMF
  cat <<EOF > $rundir/run_$casename.$arch
#!/bin/bash -l
#SBATCH --partition prod
#SBATCH --job-name ${n_p_t}
#SBATCH --time=00:02:00
#SBATCH --output=$rundir/$casename.o
#SBATCH --error=$rundir/$casename.e
# Number of nodes
#SBATCH --nodes=$nnode
# Number of MPI tasks per node
#SBATCH --ntasks-per-node=$mpiprocs
# Number of OpenMP threads per MPI task
##SBATCH --cpus-per-task=24
cd $rundir

export KMP_STACKSIZE=1GB
export I_MPI_PIN_DOMAIN=omp
#export I_MPI_PIN_DOMAIN=socket
export I_MPI_WAIT_MODE=enable
export KMP_AFFINITY=verbose,granularity=fine,compact
export OASIS_OMP_NUM_THREADS=$threads

time mpirun -np $nproces ./$exe1
EOF

###---------------------------------------------------------------------
### KRAKEN_INTEL_IMPI_OPENMP 
###---------------------------------------------------------------------
elif [ ${arch} == kraken_intel_impi_openmp ]; then
    timreq=00:30:00
    if [ ${library} == "SCRIP" ]; then
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
	
	case $remap in
	    bili)             meth_esmfname="bilinear" ; options="--extrap_method neareststod --src_loc center --dst_loc center" ;;
	    bicu)             meth_esmfname="patch" ; options="--extrap_method neareststod --src_loc center --dst_loc center" ;;
	    distwgt)          meth_esmfname="neareststod" ; options="--extrap_method neareststod --src_loc center --dst_loc center" ;;
	    conserv1st)       meth_esmfname="conserve" ; options="--ignore_unmapped --norm_type fracarea" ;;
	    conserv2nd)      meth_esmfname="conserve2nd" ; options="--ignore_unmapped --norm_type fracarea" ;;
	    *)  echo "Method $remap unknown in ESMF."
		exit ;;
	esac      
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

python $srcdir/$OasisGridsToESMF $SRC_GRID $rundir
python $srcdir/$OasisGridsToESMF $TGT_GRID $rundir
# Generate ESMF weights
time mpirun -np $nproces ESMF_RegridWeightGen -s ${SRC_GRID}_ESMF.nc -d ${TGT_GRID}_ESMF.nc -m ${meth_esmfname} -w ESMFweights.nc --ignore_degenerate ${options}

# Convert ESMF weight file in OASIS format
$srcdir/ESMFWeightsToOasis.sh ${SRC_GRID} ${TGT_GRID} ${remap}

time mpirun -np $nproces ./$exe1
EOF
    fi

elif [ $arch == belenos ] ; then
#SVSVSV a adpater a ESMF
    
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
module load intelmpi/2018.5.274
module load intel/2018.5.274
module load netcdf-fortran/4.5.2_V2
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

fi 

######################################################################
### - Execute the model

if [ ${arch} == training_computer ]; then
    export OASIS_OMP_NUM_THREADS=$threads
    MPIRUN=/usr/local/intel/impi/2018.1.163/bin64/mpirun
    echo 'Executing the model using '$MPIRUN
    $MPIRUN -np $nproces ./$exe1 > runjob.err
elif [ ${arch} == gfortran_openmpi_openmp_linux ]; then
    export OASIS_OMP_NUM_THREADS=$threads
    MPIRUN=/usr/lib64/openmpi/bin/mpirun
    echo 'Executing the model using '$MPIRUN
    $MPIRUN -np $nproces ./$exe1 > runjob.err
elif [ $arch == pgi_openmpi_openmp_linux ]; then
    MPIRUN=/usr/local/pgi/linux86-64/18.7/mpi/openmpi-2.1.2/bin/mpirun
    echo 'Executing the model using '$MPIRUN
    $MPIRUN -np $nproces ./$exe1 > runjob.err
elif [ ${arch} == gnu1020_openmpi_openmp_linux ]; then
    export OASIS_OMP_NUM_THREADS=$threads
    MPIRUN=/usr/local/openmpi/4.1.0_gcc1020/bin/mpirun
    echo 'Executing the model using '$MPIRUN
    $MPIRUN -oversubscribe -np $nproces ./$exe1 > runjob.err
elif [ $arch == pgi20.4_openmpi_openmp_linux ]; then
    MPIRUN=/usr/local/pgi/linux86-64/20.4/mpi/openmpi-3.1.3/bin/mpirun
    echo 'Executing the model using '$MPIRUN
    $MPIRUN -oversubscribe -np $nproces ./$exe1 > runjob.err
elif [ $arch == nemo_lenovo_intel_impi_openmp ]; then
    echo 'Submitting the job to queue using sbatch'
    sbatch $rundir/run_$casename.$arch
    squeue -u $USER
elif [ $arch == kraken_intel_impi_openmp ]; then
    echo 'Submitting the job to queue using sbatch'
    sbatch $rundir/run_$casename.$arch
    squeue -u $USER
elif [ $arch == belenos ]; then
    echo 'Submitting the job to queue using sbatch'
    sbatch $rundir/run_$casename.$arch
    squeue -u $user
elif [ ${arch} == mac ]; then
    echo 'Executing the model using mpirun'
    mpirun --oversubscribe -np $nproces ./$exe1
fi

echo $casename 'is executed or submitted to queue.'
echo 'Results are found in rundir : '$rundir 

######################################################################

