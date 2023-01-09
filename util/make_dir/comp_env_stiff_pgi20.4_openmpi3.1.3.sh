#!/bin/ksh

##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge
module load pgi/20.4
module load pgimpi/openmpi3.1.3_pgi20
module load lib/netcdf-c/4.6.1_pgi20.4
module load lib/netcdf-fortran/4.4.4_pgi20.4
module load python/3.7.7
echo 'We work on stiff'
echo `which mpirun`
export MPIRUN=mpirun
export corespn=1
