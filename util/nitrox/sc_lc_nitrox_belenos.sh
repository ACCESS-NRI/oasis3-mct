#!/bin/bash
#set -e

export nitrox_env=$1 
export debug=$2
export oasis_belenos=/scratch/work/coquartl/oasis3-mct/util/nitrox
export envtests_belenos=/scratch/work/coquartl/oasis3-mct/util/env_tests

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
       cd ${oasis_belenos}
       cp ${oasis_belenos}/lc_nitrox_${nitrox_env}_${debug}/env_tests_param_${nitrox_env}_${nitrox_example} ${oasis_belenos}/env_tests_param_${nitrox_env}
       ln -sf ${oasis_belenos}/env_tests_param_${nitrox_env} ${oasis_belenos}/env_tests_param
       cp ${envtests_belenos}/sc_top.sh ${oasis_belenos}/sc_top.sh
       cp ${envtests_belenos}/sc_compile_oasis.sh ${oasis_belenos}/sc_compile_oasis.sh
       cp ${envtests_belenos}/oasis_test_build.sh ${oasis_belenos}/oasis_test_build.sh
       cp ${envtests_belenos}/oasis_test_run.sh ${oasis_belenos}/oasis_test_run.sh
       cp ${envtests_belenos}/sc_launch_tests.sh ${oasis_belenos}/sc_launch_tests.sh
       cd ${oasis_belenos}
       ${oasis_belenos}/sc_top.sh ${nitrox_env}
       cd ${oasis_belenos}
       ${oasis_belenos}/sc_verif_general_lc_nitrox.sh ${nitrox_env}
       cd ${oasis_belenos}
       ${oasis_belenos}/sc_verif_fields_lc_nitrox.sh ${nitrox_env}
       cd ${oasis_belenos}
       ${oasis_belenos}/sc_verif_monopara_lc_nitrox.sh ${nitrox_env}
       cd ${oasis_belenos}
       ${oasis_belenos}/sc_verif_particular_lc_nitrox.sh ${nitrox_env}
       cd ${oasis_belenos}
done
