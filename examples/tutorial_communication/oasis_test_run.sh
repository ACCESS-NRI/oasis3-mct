#!/bin/ksh
###############################################
# USAGE : 
# Define following the variable environment:
#
# For the toys where the sources are not
# inside the oasis3-mct sources
# export OASIS_ROOT=
#
# For all the toys
# export OASIS_COUPLE=
# export OASIS_ENV=
#
# Then
# ./run_test.sh param_casename_test01
# ./run_test.sh param_casename_test02
# ...
#
# Be carefull that OASIS3-MCT is compiled
# with the same environment than the toy
###############################################

testname=$1

echo "testname = $testname"
if [ ! -f ./$testname ]; then
  echo "ERROR in param file argument, usage"
  echo "  ./oasis_test_run.sh $paramfile"
  exit -9
fi

if [ -z "${OASIS_ENV}" ]; then
  echo "ERROR OASIS_ENV not defined"
  exit -9
fi

if [ -z "${OASIS_COUPLE}" ]; then
  echo "ERROR OASIS_COUPLE not defined"
  exit -9
fi

srcdir=`pwd`
export usertoy=$srcdir
export casename=`basename $srcdir`
export pathname=`dirname $srcdir`

. ${OASIS_COUPLE}/util/make_dir/comp_env_${OASIS_ENV}.sh

#echo "module setting"
#module list

# Need to reinitialize some variables
# to run toys with different models one after the other
# Do not modify below, use $testname
export USER_EXE1=
export USER_EXE2=
export USER_EXE3=
export USER_EXE4=
export USER_EXE5=
###################################################

. ./$testname
${OASIS_COUPLE}/util/env_tests/sc_launch_tests.sh

