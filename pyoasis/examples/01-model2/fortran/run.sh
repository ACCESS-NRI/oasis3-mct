#!/bin/bash

mkdir -p work

srcdir=`pwd`
datadir=$srcdir/data
casename=`basename $srcdir`

exe1=model2

nproc_exe1=1

rundir=$srcdir/work

rm -fr $rundir
mkdir -p $rundir

#cp -f $datadir/*nc  $rundir/.
#cp -f $datadir/*.jnl $rundir/.

cp -f $srcdir/$exe1 $rundir/.

cp -f $datadir/namcouple $rundir/.

cd $rundir

mpirun -np $nproc_exe1 ./$exe1

