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
# Creation of library verification
# make.${OASIS_ENV} must exist
###############################################
###############################################
if [ -z "${OASIS_COMPILE}" ]; then
  echo "BE CAREFULL OASIS_COMPILE not defined, OASIS will not be compiled alone"
elif [ ${OASIS_COMPILE} == TRUE ]; then
	echo "OASIS_COMPILE is set to TRUE, OASIS will be compiled alone"
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
	export OASIS_TOYDIR=${toy}
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
		echo "OASIS_TOYDIR : ${OASIS_TOYDIR}"
		echo "USER_MAKELOC : ${USER_MAKELOC}"
	        cd ${OASIS_TOYDIR}
                echo "Compile $casename on ${OASIS_ENV}"
                if [ ${nb_tests} -le 9 ]; then
                        ./oasis_test_build.sh param_${casename}_test0${nb_tests}
                else
                        ./oasis_test_build.sh param_${casename}_test${nb_tests}
                fi
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
