#!/bin/ksh
##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge
module load tbb/latest
module load compiler-rt/latest
module load oclfpga/latest
module load compiler/2023.2.0
module load mkl/2023.2.0
module load mpi/2021.10.0
if [ `hostname` == calypso-globc1.calypso.cerfacs.fr ] ; then
  echo 'We work on calypso-globc1 node'
  export corespn=64
else
  echo 'We work on kraken machine'
  export corespn=192
fi
echo `which mpirun`
export MPIRUN=mpirun
module load lib/phdf5/1.12.0_impi
module load lib/netcdf-fortran/4.4.4_phdf5_1.12.0
