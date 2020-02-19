#!/bin/bash

mkdir -p work

srcdir=`pwd`
datadir=$srcdir/data
casename=`basename $srcdir`

exe1=model3a.py
exe2=model3b.py

n1=1
n2=1

rundir=$srcdir/work

rm -fr $rundir
mkdir -p $rundir

cp -f $srcdir/$exe1 $rundir/.
cp -f $srcdir/$exe2 $rundir/.

cp -f $datadir/namcouple $rundir/.

cd $rundir

mpirun -np $n1 python3 $exe1 : -np $n2 python3 $exe2

