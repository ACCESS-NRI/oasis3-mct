#!/bin/ksh
##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge
module load compiler/gcc/5.4.0
module load compiler/intel/18.0.5.274
module load mpi/intelmpi/2018.4.274
module load lib/netcdf-fortran/4.4.4
module load python/3.7.7
echo 'We work on scylla cluster'
echo `which mpirun`
export MPIRUN=mpirun
export corespn=28
