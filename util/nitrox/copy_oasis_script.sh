#!/bin/bash
# Script to copy oasis_test_build.sh and oasis_test_run.sh locally to the toys

declare -a StringArrayv1=("toy_1f1grd_to_2f2grd" "toy_auxiliary_routines" \
                          "toy_bundle" "toy_CHECKIN_BLASOLD_BLASNEW_CHECKOUT" \
                          "toy_configuration_components_A" "toy_configuration_components_ABCGH" \
                          "toy_configuration_components_B" "toy_configuration_components_C" \
		          "toy_configuration_components_CGH" "toy_create_couplcomm" \
		          "toy_gaussianreducedgrid" "toy_grids_regional_to_regional" \
		          "toy_grids_writing" "toy_identical_grids" "toy_intracomm" \
		          "toy_load_balancing" "toy_mapcons" "toy_MAPPING_options" \
		          "toy_mixed_SP_DP" "toy_multiple_fields_one_communication" \
		          "toy_NLOGPRT" "toy_NMATXRD_options" "toy_NTHRESH_STHRESH" \
		          "toy_restart_ACCUMUL_1_LAG" "toy_restart_ACCUMUL_1_NOLAG" \
		          "toy_restart_ACCUMUL_2_LAG" "toy_restart_ACCUMUL_2_NOLAG" \
		          "toy_runoff" "toy_scalar_coupling" "toy_maphot_1field" \
		          "toy_maphot_2field" "toy_time_transformations" "toy_interpolation" \
			  "toy_multiple_grids_per_partition" "toy_multiple_grids_per_partition_NOLAG")

for var in ${StringArrayv1[@]}; do
	cp /space/coquart/oasis3-mct/util/env_tests/oasis_test_build.sh /space/coquart/oasis3-mct_tests/$var/.
	cp /space/coquart/oasis3-mct/util/env_tests/oasis_test_run.sh /space/coquart/oasis3-mct_tests/$var/.
done
