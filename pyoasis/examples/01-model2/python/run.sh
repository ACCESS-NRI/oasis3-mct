#!/bin/bash

mkdir -p work

srcdir=`pwd`
datadir=$srcdir/data
casename=`basename $srcdir`

exe1=model2.py

n1=1

rundir=$srcdir/work

rm -fr $rundir
mkdir -p $rundir

cp -f $srcdir/$exe1 $rundir/.

cp -f $datadir/namcouple $rundir/.

cd $rundir

mpirun -np $n1 python3 $exe1

