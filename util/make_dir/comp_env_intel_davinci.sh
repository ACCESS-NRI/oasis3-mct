#!/bin/ksh

##########################
# Compilation environment
##########################
echo 'We work on davinci'
echo `which mpirun`
if [ -z $OASIS_DEBUG ] ; then
    export MPIRUN=mpirun
else
    export MPIRUN="mpirun -tv"
fi
export corespn=1
