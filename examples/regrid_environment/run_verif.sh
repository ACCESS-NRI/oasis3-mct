#!/bin/ksh
#set -x
srcdir=`pwd`
n_p_t=$1
library=$2
ext=$3
casename=`basename $srcdir`
fileres=$srcdir/RUNDIR_${library}_${ext}/resu_${n_p_t}_${library}.txt
echo $n_p_t > $fileres
cd RUNDIR_${library}_${ext}
for rundir in `ls -d ${casename}_*_${n_p_t}_*` ; do
    resu=`grep "Error mean" ${rundir}/model1.out_100 | awk -F " " '{print $12}'`
    echo ${rundir} ' : ' ${resu} >> $fileres
done
echo 'Differences'
echo `diff $srcdir/resu_${library}.txt_OK $fileres`
