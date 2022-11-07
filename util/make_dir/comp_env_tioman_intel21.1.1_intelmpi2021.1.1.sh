#!/bin/ksh

##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge
module load intel/21.1.1
module load intelmpi/2021.1.1
module load lib/netcdf-fortran/4.4.4_phdf5_1.10.4
module load python/3.7.7
echo 'We work on tioman'
echo `which mpirun`
export MPIRUN=mpirun
export corespn=1
