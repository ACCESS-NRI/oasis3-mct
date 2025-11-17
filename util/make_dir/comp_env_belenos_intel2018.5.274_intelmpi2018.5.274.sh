#!/bin/ksh

##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge > /dev/null 2>&1
module load gcc/9.2.0 > /dev/null 2>&1
module load intel/2018.5.274 > /dev/null 2>&1
module load intelmpi/2018.5.274 > /dev/null 2>&1
module load netcdf-fortran/4.5.2_V2 > /dev/null 2>&1
module load netcdf-c/4.7.1_V2 > /dev/null 2>&1
module load python/3.7.6 > /dev/null 2>&1
module load nco/5.0.6 > /dev/null 2>&1
echo 'We work on belenos'
echo `which mpirun`
export MPIRUN=mpirun
export corespn=128
