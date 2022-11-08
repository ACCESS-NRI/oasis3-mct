#!/bin/bash
set -e

export nitrox_env=$1 
export nitrox_oasis_root=$2

declare -a StringArrayv1=("compile" "toy_1f1grd_to_2f2grd") 
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
