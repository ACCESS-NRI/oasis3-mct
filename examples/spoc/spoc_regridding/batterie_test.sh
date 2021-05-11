#!/bin/ksh
#set -xv
\rm resu.txt
for run in bggd_nogt_conserv1st bggd_nogt_conserv2nd bggd_nogt_bicu ssea_nogt_bicu icos_nogt_distwgt  ; do
   if [ -f "resu.txt" ] ; then
      echo "############################################" >> resu.txt
   else
      echo "############################################" > resu.txt
   fi
   echo $run >> resu.txt
   src=`echo $run | awk -F _ '{print $1}'`
   tgt=`echo $run | awk -F _ '{print $2}'`
   remap=`echo $run | awk -F _ '{print $3}'` 
   echo $src $tgt $remap
   for arg in 2_1_1 2_4_1 2_1_8 ; do
      dir=spoc_regridding_${run}_${arg}
      \rm -rf $dir
      ./run_regrid.sh $src $tgt $remap $arg
   done
#
   squeue -u valcke > sq.resu
   nline=`wc -l sq.resu | awk -F " " '{print $1}'`
   echo $nline
   while [ $nline  -ne 1 ] ; do
      squeue -u valcke > sq.resu
      sleep 2
      nline=`wc -l sq.resu | awk -F " " '{print $1}'`
   done
   for arg in 2_1_1 2_4_1 2_1_8 ; do
     dir=spoc_regridding_${run}_${arg}
     grep MINVAL $dir/model2.out >> resu.txt
     grep 'Max (%)' $dir/model2.out >> resu.txt
     grep 'Error mean' $dir/model2.out >> resu.txt
   done
done
diff resu.txt resu_comp.txt > diff.txt
nline=`wc -l diff.txt | awk -F " " '{print $1}'`
if [ nline -ne 0 ] ; then
   echo 'There are problems'
else
   echo 'Everything OK'
fi

