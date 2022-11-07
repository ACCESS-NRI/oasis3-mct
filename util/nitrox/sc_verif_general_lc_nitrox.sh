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
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                echo "Get the SUCCESSFUL RUN results in debug files"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                file_res_end='res_end_successful_'${rundirname}
		file_diff_successful_run='diff_res_ref_successful_run_'${rundirname}
		ls debug.*
                res_command=`echo $?`
                if [ ${res_command} -ne 0 ]; then
                   echo "debug files not created"
                   exit 1
                fi
                grep -i 'MPI_Finalize' debug.* > $file_res_end
                grep -i 'SUCCESSFUL RUN' debug.* >> $file_res_end
                diff $file_res_end ${DIR_RES_REF}/${rundirname}/$file_res_end > $file_diff_successful_run
                ls $file_diff_successful_run
                cp  $file_diff_successful_run ${USER_RUNDIR}/$file_diff_successful_run
		cp $file_res_end ${USER_RUNDIR}/$file_res_end 
		if [ -s ${USER_RUNDIR}/$file_diff_successful_run ]; then
                   echo "-------------------------------------------------------------------"
                   echo "WARNING : pb running the toy ${rundirname}" 
                   echo "-------------------------------------------------------------------"
                   exit 1
                fi
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                echo "Get the min and max IO number in nout file"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                file_io_number='res_io_number'
		file_diff_io_number='diff_res_ref_io_number_'${rundirname}
		ls nout.*
                res_command=`echo $?`
                if [ ${res_command} -ne 0 ]; then
                   echo "nout file not created"
                   exit 1
                fi
                grep -i 'The min IO unit number is' nout.* > $file_io_number
                grep -i 'The max IO unit number' nout.* >> $file_io_number
                diff $file_io_number ${DIR_RES_REF}/${rundirname}/$file_io_number > $file_diff_io_number
                ls $file_diff_io_number
                cp  $file_diff_io_number ${USER_RUNDIR}/$file_diff_io_number
		if [ -s ${USER_RUNDIR}/$file_diff_io_number ]; then
                   echo "-------------------------------------------------------------------"
                   echo "WARNING : pb with IO number for the toy ${rundirname}"
                   echo "-------------------------------------------------------------------"
                   exit 1
                fi
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                echo "Compare the diags (field statistics) if any"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		file_results_diags='results_diags'
		file_diff_results_diags='diff_res_ref_diags_'${rundirname}
		awk '/diags:/, /****/ {print $0}' debug.* > file_results_stat_tmp
                awk '{ printf  "%10s %10s %10.5f %10.5f %20.7f\n", $1 , $2, $3, $4, $5 }' file_results_stat_tmp > $file_results_diags
#
                diff $file_results_diags ${DIR_RES_REF}/${rundirname}/$file_results_diags > $file_diff_results_diags
                ls $file_diff_results_diags
                cp $file_diff_results_diags ${USER_RUNDIR}/$file_diff_results_diags
		if [ -s ${USER_RUNDIR}/$file_diff_results_diags ]; then
                   echo "-------------------------------------------------------------------"
                   echo "WARNING : pb with the diags for the toy ${rundirname}"
                   echo "-------------------------------------------------------------------"
                   exit 1
                fi
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                echo "Compare model*.out* or comp*.out* content"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                file_results_models_out='results_models_out'
		file_diff_models_out='diff_models_out_'${rundirname}
		if [ $casename == toy_configuration_components_A ] || [ $casename == toy_configuration_components_B ]; then
			ls comp*.out*
			cat comp*.out* > $file_results_models_out
		else
			ls model*.out*
			cat model*.out* > $file_results_models_out
		fi
		diff $file_results_models_out ${DIR_RES_REF}/${rundirname}/$file_results_models_out > $file_diff_models_out
                ls $file_diff_models_out
                cp $file_diff_models_out ${USER_RUNDIR}/$file_diff_models_out
		if [ -s ${USER_RUNDIR}/$file_diff_models_out ]; then
                   echo "-------------------------------------------------------------------"
                   echo "WARNING : pb with model or comp files for the toy ${rundirname}"
                   echo "-------------------------------------------------------------------"
                   exit 1
                fi
        done
	(( nbtoy=nbtoy+1 ))
done
###############################################
###############################################
