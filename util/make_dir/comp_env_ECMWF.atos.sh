#!/bin/bash -x

##########################
# Compilation environment
##########################
  module purge
  module load prgenv/gnu
  module load ecflow/5.7.0
  module load openmpi/4.1.1.1
  module load openblas/0.3.9
  module load netcdf4/4.8.1
  module load hdf5/1.10.6
  module load ecmwf-toolbox/2021.08.3.0
  module load python3/3.8.8-01
  module load gdal/3.2.1

echo 'We work on atos'
echo `which mpirun`
export MPIRUN=mpirun
#Cores per node?
#export corespn=128
export corespn=128



