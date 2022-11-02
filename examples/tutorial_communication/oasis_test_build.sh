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
# export OASIS_ARCH=
#
# Then
# ./run_test.sh param_casename_test01
# ./run_test.sh param_casename_test02
# ...
#
# Be carefull that OASIS3-MCT is compiled
# with the same environment than the toy
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

#echo "module setting"
#module list

make clean
make


