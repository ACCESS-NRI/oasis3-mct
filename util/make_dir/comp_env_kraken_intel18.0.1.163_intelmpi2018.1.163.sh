#!/bin/ksh
##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge
module load compiler/intel/18.0.1.163
module load mpi/intelmpi/2018.1.163
module load lib/netcdf-fortran/4.4.4_impi
module load lib/phdf5/1.8.20_impi 
module load python/3.7.7
echo 'We work on Kraken'
echo `which mpirun`
export MPIRUN=mpirun
export corespn=36
