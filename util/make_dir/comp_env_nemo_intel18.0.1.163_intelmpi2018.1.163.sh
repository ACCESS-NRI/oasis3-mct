#!/bin/ksh
##########################
# Compilation environment
##########################
source /etc/profile.d/modules.sh
module purge
module load compiler/intel/18.0.1.163
module load mpi/intelmpi/2018.1.163-ddt
module load lib/phdf5/1.10.4_impi
module load lib/netcdf-fortran/4.4.4_phdf5_1.10.4
module load python/3.7.7
echo 'We work on nemo_lenovo'
echo `which mpirun`
export MPIRUN=mpirun
export corespn=24
