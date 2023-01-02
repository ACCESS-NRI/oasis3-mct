#!/bin/ksh
#set -xv
###############################################
###############################################
# Link the correct env_tests_param
###############################################
###############################################
envcomp=$1
echo "envcomp=$envcomp"
if [ -z "$1" ]; then
    echo "No environment argument supplied"
    exit -9
fi
ln -sf env_tests_param_${envcomp} env_tests_param
. ./env_tests_param
###############################################
###############################################
# Loop over the toys: 
# Verification of the results
###############################################
echo "sc_verif_monopara_lc_nitrox.sh script"
nbtoy=0
for toy in ${USER_TOY[@]}; do
	echo "+++++++++++++++++++++++++++++++++++++++"
	echo "+++++++++++++++++++++++++++++++++++++++"
	echo "toy :" $toy
	export casename=`basename $toy`
	echo "casename :" $casename
	echo "+++++++++++++++++++++++++++++++++++++++"
	echo "+++++++++++++++++++++++++++++++++++++++"
	export pathname=`dirname $toy`
	export paramloc=${USER_PARAMLOC[$nbtoy]}
	echo "Localisation of the parameter test files for the toy" $paramloc
        export nbttot=${USER_TEST[$nbtoy]}
	echo "Total number of tests " $nbttot " for toy " ${casename}
	for nb_tests in $( eval echo {1..${nbttot}} ); do
		echo "Test number : " ${nb_tests}
                export USER_EXE1=
                export USER_EXE2=
                export USER_EXE3=
                export USER_EXE4=
                export USER_EXE5=
	        cd $paramloc
		if [ ${nb_tests} -le 9 ]; then
			. ./param_${casename}_test0${nb_tests}
		else
			. ./param_${casename}_test${nb_tests}
		fi
		. ./nitrox_fields_${casename}
		set -A models
                set -A pecnts

                for nmodels in {1..5}
                do
                   if [ ${nmodels} == 1 ]; then
                      nmod=${USER_EXE1}
                      npes=${USER_NPEXE1}
                   elif [ ${nmodels} == 2 ]; then
                      nmod=${USER_EXE2}
                      npes=${USER_NPEXE2}
                   elif [ ${nmodels} == 3 ]; then
                      nmod=${USER_EXE3}
                      npes=${USER_NPEXE3}
                    elif [ ${nmodels} == 4 ]; then
                      nmod=${USER_EXE4}
                      npes=${USER_NPEXE4}
                    elif [ ${nmodels} == 5 ]; then
                      nmod=${USER_EXE5}
                      npes=${USER_NPEXE5}
                    fi
		    if [ "${nmod:-unset}" != "unset" ]; then
                         if [ ${#models[@]} == 0 ]; then
                            models=(${nmod})
                            pecnts=(${npes})
                         else
                            models+=(${nmod})
                            pecnts+=(${npes})
                         fi
                     fi
                done
		rundirname="work_${casename}_${USER_NAMCOUPLE}_${USER_MAKEFILE}"
		rundirname_mono="work_${casename}_${USER_NAMCOUPLE}_${USER_MAKEFILE}"
                for imodel in {1..${#models[@]}}
                do
                   let im=${imodel}-1
                   echo ${models[$im]}' runs on '${pecnts[$im]}' processes'
                   rundirname="${rundirname}_${models[$im]}_${pecnts[$im]}"
		   rundirname_mono="${rundirname_mono}_${models[$im]}_1"
                done
		echo "rundirname $rundirname"
		echo "rundirname_mono ${rundirname_mono}"
                export rundir=${USER_RUNDIR}/${rundirname}
		if [ $casename == toy_1f1grd_to_2f2grd ] || [ $casename == toy_bundle ] || [ $casename == toy_CHECKIN_BLASOLD_BLASNEW_CHECKOUT ] || [ $casename == toy_gaussianreducedgrid ] || [ $casename == toy_grids_regional_to_regional ] || [ $casename == toy_intracomm ] || [ $casename == toy_multiple_fields_one_communication ] || [ $casename == toy_NTHRESH_STHRESH ] || [ $casename == toy_runoff ] || [ $casename == toy_interpolation ]; then
	        cd ${rundir}
		nbfield=1
		for field in ${USER_FIELDS[@]}; do
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                    echo "Compare coupling fields for mono and para"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                    echo 'Field number:' $nbfield, $field
		    ls $field
		    res_command=`echo $?`
                    if [ ${res_command} -ne 0 ]; then
                       echo "pb" $field "does not exist"
                       exit 1
                    fi
		    file_results_field='results_field'${nbfield}
		    file_diff_results_field_mono_para='diff_field'${nbfield}'_with_mono_'${rundirname}
		    diff $file_results_field ${USER_RUNDIR}/$rundirname_mono/$file_results_field > $file_diff_results_field_mono_para
		    ls $file_diff_results_field_mono_para
		    cp $file_diff_results_field_mono_para ${USER_RUNDIR}/$file_diff_results_field_mono_para
     		    if [ -s ${USER_RUNDIR}/$file_diff_results_field_mono_para ]; then
                       echo "-------------------------------------------------------------------"
                       echo "WARNING : pb diff mono-para for the toy ${rundirname}" 
                       echo "-------------------------------------------------------------------"
                       exit 1
                    fi
		    (( nbfield=nbfield+1 ))
	        done
	        fi
        done
	(( nbtoy=nbtoy+1 ))
done
###############################################
###############################################
