#!/bin/ksh
##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge > /dev/null
module load tbb/latest > /dev/null
module load compiler-rt/latest > /dev/null
module load oclfpga/latest > /dev/null
module load compiler/2023.2.0 > /dev/null
module load mkl/2023.2.0 > /dev/null
module load mpi/2021.10.0 > /dev/null
if [ `hostname` == calypso-globc1.calypso.cerfacs.fr ] ; then
  echo 'We work on calypso-globc1 node'
  export corespn=64
else
  echo 'We work on calypso machine'
  export corespn=192
fi
echo `which mpirun`
export MPIRUN=mpirun
export I_MPI_COLL_EXTERNAL=no
module load lib/phdf5/1.12.0_impi > /dev/null
module load lib/netcdf-fortran/4.4.4_phdf5_1.12.0 > /dev/null
