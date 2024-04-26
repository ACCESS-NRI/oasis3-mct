#!/bin/ksh
##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge
module load compiler/gcc/5.4.0
module load compiler/intel/18.0.1.163

if [ `hostname` == kglobc1 ] ; then
  module load mpi/intelmpi/2018.1.163_ssh
  echo 'We work on kglobc1 node'
  export corespn=64
else
  module load mpi/intelmpi/2018.1.163
  echo 'We work on kraken machine'
  export corespn=36
fi

echo `which mpirun`
export MPIRUN=mpirun
module load lib/netcdf-fortran/4.4.4_impi
module load lib/phdf5/1.8.20_impi 
module load python/3.7.7
