#!/bin/ksh

##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge
module load intelmpi/2018.5.274
module load intel/2018.5.274
module load netcdf-fortran/4.5.2_V2
module load netcdf-c/4.7.1_V2
module load python/3.7.6
echo 'We work on belenos'
echo `which mpirun`
export MPIRUN=mpirun
export corespn=128
