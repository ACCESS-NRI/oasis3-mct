#!/bin/bash
set -e

export nitrox_env=$1 
export nitrox_oasis_root=$2

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
       ./sc_top.sh ${nitrox_env} ${nitrox_oasis_root}
       ./sc_verif_general_lc_nitrox.sh ${nitrox_env}
       ./sc_verif_fields_lc_nitrox.sh ${nitrox_env}
       ./sc_verif_monopara_lc_nitrox.sh ${nitrox_env}
       ./sc_verif_particular_lc_nitrox.sh ${nitrox_env}
done
