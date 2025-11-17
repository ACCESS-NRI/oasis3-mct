#!/bin/ksh
##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge
module load compiler/gcc/11.2.0
module load compiler/intel/23.2.1
module load mpi/intelmpi/2021.10.0
if [ `hostname` == kglobc1 ] ; then
  echo 'We work on kglobc1 node'
  export corespn=64
else
  echo 'We work on kraken machine'
  export corespn=36
fi
echo `which mpirun`
export MPIRUN=mpirun
module load lib/netcdf-fortran/4.4.4_phdf5_1.10.4
module load tools/nco/4.7.6
