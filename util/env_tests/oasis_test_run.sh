#!/bin/ksh
set -xv
###############################################
# USAGE : 
# Define following the variable environment:
#
# For all the toys
# export OASIS_COUPLE=
# export OASIS_ENV=
#
# Then
# ./oasis_test_run.sh param_casename_test01
# ./oasis_test_run.sh param_casename_test02
# ...
# 
# The param file that is in argument of oasis_test_run.sh
# is a file that exists in the toy
# directory and specifies several aspects of the each test run
#
# Be carefull that OASIS3-MCT is compiled
# with the same environment than the toy
###############################################

testname=$1

echo "testname = $testname"
if [ ! -f ./$testname ]; then
  echo "ERROR in param file argument, usage"
  echo "  ./oasis_test_run.sh \$testname"
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
export casename=`basename $srcdir`
export pathname=`dirname $srcdir`

if [ -z "${OASIS_TOYDIR}" ]; then
  export OASIS_TOYDIR=`pwd`
  echo "OASIS_TOYDIR is by default ${OASIS_TOYDIR}"
else
  echo "OASIS_TOYDIR is set in sc_top.sh and is ${OASIS_TOYDIR}"
fi

if [ -z "${USER_RUNDIR}" ]; then
  export USER_RUNDIR=${OASIS_TOYDIR}/TESTS
  echo "USER_RUNDIR is by default ${OASIS_TOYDIR}/TESTS"
else
  echo "USER_RUNDIR is set in env_param file and is ${USER_RUNDIR}"
fi

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

