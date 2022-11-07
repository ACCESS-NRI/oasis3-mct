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
# Compilation of OASIS3-MCT OR PYOASIS only once
# Creation of librairy verification
# comp_env_${OASIS_ENV}.sh and make.${OASIS_ENV}
# must exist
###############################################
###############################################
if [ -z "${OASIS_ENV}" ]; then
  echo "ERROR OASIS_ENV not defined"
  exit -9
fi

if [ -z "${OASIS_COUPLE}" ]; then
  echo "ERROR OASIS_COUPLE not defined"
  exit -9
fi
. ${OASIS_COUPLE}/util/make_dir/comp_env_${OASIS_ENV}.sh
#
if [ ${OASIS_COMPILE} == TRUE ]; then
	. ./sc_compile_oasis.sh
fi
###############################################
###############################################
# Loop over the toys: 
# compilation 
# sc_launch_test call
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
                # Compilation of the toy for this test
		export usertoy=${toy}
	        cd ${toy}
		cp -f ${USER_MAKELOC}/${USER_MAKEFILE} ${toy}/Makefile
                echo "Compile $casename on ${OASIS_ENV}"
                ./oasis_test_build.sh
###############################################
               	if [ ${nb_tests} -le 9 ]; then
			./oasis_test_run.sh param_${casename}_test0${nb_tests}
		else
			./oasis_test_run.sh param_${casename}_test${nb_tests}
		fi
        done
	(( nbtoy=nbtoy+1 ))
done
###############################################
###############################################
