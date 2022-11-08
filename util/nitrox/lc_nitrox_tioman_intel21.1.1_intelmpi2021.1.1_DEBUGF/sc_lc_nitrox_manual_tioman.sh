#!/bin/bash
set -e

export nitrox_env=tioman_intel21.1.1_intelmpi2021.1.1 
export nitrox_oasis_root=/space/coquart/oasis3-mct/util/nitrox

declare -a StringArrayv1=("compile" "toy_1f1grd_to_2f2grd" "toy_auxiliary_routines" \
                          "toy_bundle" "toy_CHECKIN_BLASOLD_BLASNEW_CHECKOUT" \
                          "toy_configuration_components_A" "toy_configuration_components_ABCGH" \
                          "toy_configuration_components_B" "toy_configuration_components_C" \
		          "toy_configuration_components_CGH" "toy_create_couplcomm" \
		          "toy_gaussianreducedgrid" "toy_grids_regional_to_regional" \
		          "toy_grids_writing" "toy_identical_grids" "toy_intracomm" \
		          "toy_load_balancing" "toy_mapcons" "toy_MAPPING_options" \
		          "toy_mixed_SP_DP" "toy_multiple_fields_one_communication" \
		          "toy_NLOGPRT" "toy_NMATXRD_options" "toy_NTHRESH_STHRESH" \
			  "toy_time_transformations"
		          "toy_restart_ACCUMUL_1_LAG" "toy_restart_ACCUMUL_1_NOLAG" \
		          "toy_restart_ACCUMUL_2_LAG" "toy_restart_ACCUMUL_2_NOLAG" \
		          "toy_runoff" "toy_scalar_coupling" "toy_interpolation")
for nitrox_example in ${StringArrayv1[@]}; do
echo '-------------------------------------------------'
echo 'TOY TESTED     : '${nitrox_example}
echo '-------------------------------------------------'
       cp lc_nitrox_${nitrox_env}/env_tests_param_${nitrox_env}_${nitrox_example} env_tests_param_${nitrox_env}
       NEW_OASIS_ROOT=`dirname ${nitrox_oasis_root}`
       sed -i 's+OASIS_ROOT=/space/coquart+OASIS_ROOT=${NEW_OASIS_ROOT}+g' env_tests_param_${nitrox_env}
       sed -i 's+OASIS_COUPLE=${OASIS_ROOT}/oasis3-mct+OASIS_COUPLE=/home/globc/coquart/${nitrox_oasis_root}+g' env_tests_param_${nitrox_env}
echo "PATHS changed in env_tests_param_${nitrox_env}"
       cp ../env_tests/sc_top.sh sc_top.sh
       cp ../env_tests/sc_compile_oasis.sh sc_compile_oasis.sh
       cp ../env_tests/oasis_test_build.sh oasis_test_build.sh
       cp ../env_tests/oasis_test_run.sh oasis_test_run.sh
       cp ../env_tests/sc_launch_tests.sh sc_launch_tests.sh
       ./sc_top.sh ${nitrox_env}
       ./sc_verif_general_lc_nitrox.sh ${nitrox_env}
       ./sc_verif_fields_lc_nitrox.sh ${nitrox_env}
       ./sc_verif_monopara_lc_nitrox.sh ${nitrox_env}
       ./sc_verif_particular_lc_nitrox.sh ${nitrox_env}
done
