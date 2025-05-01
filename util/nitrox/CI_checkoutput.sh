#!/bin/ksh

. ./env_tests_param_$1

#dresref=OA3-MCT_RES_REF
#dres=OA3-MCT_RES
dresref=${DIR_RES_REF}
dres=${USER_RUNDIR}

output=$dres/CI_check_output.out
echo -e '   !!!!!!!!!!!!!!!\n   Check output CI\n   !!!!!!!!!!!!!!!\n'
echo -e '   !!!!!!!!!!!!!!!\n   Check output CI\n   !!!!!!!!!!!!!!!\n' > $output

echo '   Number of reference toys: '`grep -i -m1 "SUCCESSFUL RUN" $dresref/res_end_successful_* | wc -l`
echo '   Number of reference toys: '`grep -i -m1 "SUCCESSFUL RUN" $dresref/res_end_successful_* | wc -l` >> $output
echo '   Number of successfully executed toys: '`grep -i -m1 "SUCCESSFUL RUN" $dres/res_end_successful_* | wc -l`
echo '   Number of successfully executed toys: '`grep -i -m1 "SUCCESSFUL RUN" $dres/res_end_successful_* | wc -l` >> $output
echo
echo >> $output

dif=false
for file_diff in `ls -1 $dres/diff_*`; do
   if [ -s $file_diff ]; then
      echo '   /!\ File '$file_diff' is not empty! At least one difference with reference in '$dresref
      echo '   /!\ File '$file_diff' is not empty! At least one difference with reference in '$dresref >> $output
      echo
      echo >> $output
      dif=true
   fi
done
if [ $dif == "false" ]; then
   echo '   No difference with reference for all toys: all diff_* files are empty'
   echo '   No difference with reference for all toys: all diff_* files are empty' >> $output
   echo
   echo >> $output
fi
