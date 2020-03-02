#!/bin/bash

datadir=data

exe1=model3a
exe2=model3b

n1=1
n2=1

rundir=work 

mkdir -p $rundir

cp -f $exe1 $rundir/.
cp -f $exe2 $rundir/.
 
cp -f $datadir/namcouple $rundir/namcouple

cd $rundir

export OMP_NUM_THREADS=1

mpirun -np $n1 ./$exe1 : -np $n2 ./$exe2 
