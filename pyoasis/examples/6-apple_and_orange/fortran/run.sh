#!/bin/bash

mkdir -p work

srcdir=`pwd`
datadir=$srcdir/data
casename=`basename $srcdir`

exe1=sender-apple
exe2=receiver-orange

n1=4
n2=4

rundir=$srcdir/work

rm -fr $rundir
mkdir -p $rundir

cp -f $srcdir/$exe1 $rundir/.
cp -f $srcdir/$exe2 $rundir/.

cp -f $datadir/namcouple $rundir/.

cd $rundir

mpirun --oversubscribe -np $n1 $exe1 : -np $n2  $exe2
