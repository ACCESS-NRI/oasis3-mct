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
                for imodel in {1..${#models[@]}}
                do
                   let im=${imodel}-1
                   echo ${models[$im]}' runs on '${pecnts[$im]}' processes'
                   rundirname="${rundirname}_${models[$im]}_${pecnts[$im]}"
                done
                export rundir=${USER_RUNDIR}/${rundirname}
	        cd ${rundir}
		nbfield=1
		for field in ${USER_FIELDS[@]}; do
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                    echo "Get the the coupling field results"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                    echo 'Field number:' $nbfield, $field
                    file_results_field='results_field'${nbfield}
		    file_diff_results_field='diff_field'${nbfield}'_'${rundirname}
		    ls $field
		    res_command=`echo $?`
                    if [ ${res_command} -ne 0 ]; then
                       echo "pb" $field "does not exist"
                       exit 1
                    fi
                    ncdump -p 6,8 $field > toto
                    sed --silent '/history/ !p' toto > $file_results_field
                    diff $file_results_field ${DIR_RES_REF}/${rundirname}/$file_results_field > $file_diff_results_field
                    ls $file_diff_results_field
                    cp  $file_diff_results_field ${USER_RUNDIR}/$file_diff_results_field
     		    if [ -s ${USER_RUNDIR}/$file_diff_results_field ]; then
                       echo "-------------------------------------------------------------------"
                       echo "WARNING : pb field $nbfield, $field for the toy ${rundirname}" 
                       echo "-------------------------------------------------------------------"
                       exit 1
                    fi
		    (( nbfield=nbfield+1 ))
	        done
        done
	(( nbtoy=nbtoy+1 ))
done
###############################################
###############################################
