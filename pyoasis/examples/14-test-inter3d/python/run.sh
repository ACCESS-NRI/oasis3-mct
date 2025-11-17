#!/bin/bash

mkdir -p work

srcdir=`pwd`
datadir=$srcdir/../common_data
casename=`basename $srcdir`

exe1=sender-cube.py
exe2=receiver.py

n1=4
n2=1

rundir=$srcdir/work

rm -fr $rundir
mkdir -p $rundir

ln -sf $srcdir/$exe1 $rundir/.
ln -sf $srcdir/$exe2 $rundir/.
ln -sf $srcdir/$uti $rundir/.

ln -sf $datadir/grids.nc $rundir/.
ln -sf $datadir/masks.nc $rundir/.

ln -sf $datadir/namcouple $rundir/.

ln -sf $datadir/rmp_nogt_to_torc_CONSERV_FRACNNEI.nc $rundir/.
ln -sf $datadir/rmp_nol2_to_tol2_CONSERV_FRACNNEI.nc $rundir/.
ln -sf $datadir/rmp_nol3_to_tol3_CONSERV_FRACNNEI.nc $rundir/.
ln -sf $datadir/rmp_no3d_to_to3d_CONSERV_FRACNNEI.nc $rundir/.

ln -sf $datadir/cartopy $rundir/.

cd $rundir

${MPIRUN4PY} -np $n1 python3 $exe1 : -np $n2 python3 $exe2
