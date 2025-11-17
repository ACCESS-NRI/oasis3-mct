#!/bin/ksh
##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge
module load compiler/gcc/11.2.0
module load mpi/openmpi/4.1.1_gcc112
if [ `hostname` == kglobc1 ] ; then
  echo 'We work on kglobc1 node'
  export corespn=64
else
  echo 'We work on kraken machine'
  export corespn=36
fi
echo `which mpirun`
export MPIRUN=mpirun
module load lib/phdf5/1.10.8_gcc112_ompi411
module load lib/netcdf-fortran/4.4.4_phdf5_1.10.8_ompi_gcc112
module load tools/nco/4.7.6
