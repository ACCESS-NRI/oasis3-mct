#!/bin/ksh

##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge
module load openmpi/410_gcc1020
module load lib/netcdf-fortran/4.4.4_gcc1020
module load python/3.7.7
echo 'We work on fundy'
echo `which mpirun`
export MPIRUN=mpirun
export corespn=1
