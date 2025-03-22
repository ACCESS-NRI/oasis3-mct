#!/bin/bash

mkdir -p work

srcdir=`pwd`
datadir=$srcdir/../common_data
casename=`basename $srcdir`

exe1=sender-apple.py
exe2=receiver.py
uti=utils.py

n1=4
n2=1

rmplibs="scrip yac"
tgtgrids="bggd bgnc"

for rmplib in $rmplibs ; do
   for tgtgrid in $tgtgrids ; do
      rundir=$srcdir/work/$rmplib/

      rm -fr $rundir
      mkdir -p $rundir

      ln -sf $srcdir/$exe1 $rundir/.
      ln -sf $srcdir/$exe2 $rundir/.
      ln -sf $srcdir/$uti $rundir/.

      ln -sf $datadir/grids.nc $rundir/.
      ln -sf $datadir/areas.nc $rundir/.

      ln -sf $datadir/cartopy $rundir/.

      cd $rundir

      cat > test_input.in <<EOF
$rmplib
nogt
$tgtgrid
no
EOF

      ${MPIRUN4PY} -np $n1 python3 $exe1 < test_input.in : -np $n2 python3 $exe2
   done
done
