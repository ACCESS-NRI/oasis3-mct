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
# Loop over the toys: 
# Verification of the results
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
		set -A models
                set -A pecnts

                for nmodels in {1..5}
                do
                   if [ ${nmodels} == 1 ]; then
                      nmod=${USER_EXE1}
                      npes=${USER_NPEXE1}
                   elif [ ${nmodels} == 2 ]; then
                      nmod=${USER_EXE2}
                      npes=${USER_NPEXE2}
                   elif [ ${nmodels} == 3 ]; then
                      nmod=${USER_EXE3}
                      npes=${USER_NPEXE3}
                    elif [ ${nmodels} == 4 ]; then
                      nmod=${USER_EXE4}
                      npes=${USER_NPEXE4}
                    elif [ ${nmodels} == 5 ]; then
                      nmod=${USER_EXE5}
                      npes=${USER_NPEXE5}
                    fi
		    if [ "${nmod:-unset}" != "unset" ]; then
                         if [ ${#models[@]} == 0 ]; then
                            models=(${nmod})
                            pecnts=(${npes})
                         else
                            models+=(${nmod})
                            pecnts+=(${npes})
                         fi
                     fi
                done
		rundirname="work_${casename}_${USER_NAMCOUPLE}_${USER_MAKEFILE}"
                for imodel in {1..${#models[@]}}
                do
                   let im=${imodel}-1
                   echo ${models[$im]}' runs on '${pecnts[$im]}' processes'
                   rundirname="${rundirname}_${models[$im]}_${pecnts[$im]}"
                done
                export rundir=${USER_RUNDIR}/${rundirname}
                if [ $casename == toy_multiple_fields_one_communication ] || [ $casename == toy_time_transformations ] || [ $casename == toy_restart_ACCUMUL_1_NOLAG ] || [ $casename == toy_restart_ACCUMUL_1_LAG ] || [ $casename == toy_restart_ACCUMUL_2_NOLAG ] || [ $casename == toy_restart_ACCUMUL_2_LAG ]; then
	           cd ${rundir}
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                   echo "Compare the restart files written at the end of the run"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                   file_results_restart1_model1='results_restart_oceannc_model1'
		   file_diff_results_restart1_model1='diff_results_restart_oceannc_model1_'${rundirname}   
		   ncdump -p 6,8 ocean.nc > toto
                   sed --silent '/history/ !p' toto > $file_results_restart1_model1
                   diff $file_results_restart1_model1 ${DIR_RES_REF}/${rundirname}/$file_results_restart1_model1 > $file_diff_results_restart1_model1
                   ls $file_diff_results_restart1_model1
		   cp $file_diff_results_restart1_model1 ${USER_RUNDIR}/$file_diff_results_restart1_model1
                   if [ -s ${USER_RUNDIR}/$file_diff_results_restart1_model1 ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb with restart ocean.nc for ${rundirname}" 
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
                fi
                if [ $casename == toy_time_transformations ]; then
	           cd ${rundir}
	           file_results_FRECVATM_end='results_FRECVATM_end'
	           ncks -d time,3 FRECVATM_model2_01.nc toto.nc
	           ncdump -p 6,8 toto.nc > titi
	           sed --silent '/history/ !p' titi > $file_results_FRECVATM_end
ed  ${USER_RUNDIR}/${rundirname}/$file_results_FRECVATM_end <<EOF
g/time = 43200/s/time = 43200/time = 0
w
q
EOF
                echo "time = 43200"
                fi
		if [ $casename == toy_restart_ACCUMUL_2_NOLAG ]; then
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                   echo "Compare $casename with toy_time_transformations, namcouple_1"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	           cd ${rundir}
                   file_results_FRECVATM_end='results_FRECVATM_end'
		   file_results_restart1_model1='results_restart_oceannc_model1'
                   ncks -d time,0 FRECVATM_model2_01.nc toto.nc
                   ncdump -p 6,8 toto.nc > titi
                   sed --silent '/history/ !p' titi > $file_results_FRECVATM_end
		   file_diff_FRECVATM_toy1_toy2='diff_FRECVATM_toy_time_transformations_namcouple_1'
                   file_diff_restart1_toy1_toy2='diff_oceannc_restart_toy_time_transformations_namcouple_1'
		   diff $file_results_FRECVATM_end ${USER_RUNDIR}/work_toy_time_transformations_namcouple_1_Makefile_1_model1_1_model2_1/$file_results_FRECVATM_end > $file_diff_FRECVATM_toy1_toy2
		   diff $file_results_restart1_model1 ${USER_RUNDIR}/work_toy_time_transformations_namcouple_1_Makefile_1_model1_1_model2_1/$file_results_restart1_model1 > $file_diff_restart1_toy1_toy2
		   cp $file_diff_FRECVATM_toy1_toy2 ${USER_RUNDIR}/$file_diff_FRECVATM_toy1_toy2
		   cp $file_diff_restart1_toy1_toy2 ${USER_RUNDIR}/$file_diff_restart1_toy1_toy2
	           if [ -s ${USER_RUNDIR}/$file_diff_FRECVATM_toy1_toy2 ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb with FRECVATM for the toy time_transformations and ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_restart1_toy1_toy2 ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb with restart for the toy time_transformations and ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		fi
		if [ $casename == toy_restart_ACCUMUL_2_LAG ]; then
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                   echo "Compare $casename with toy_time_transformations, namcouple_5"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	           cd ${rundir}
		   file_results_FRECVATM_end='results_FRECVATM_end'
		   file_results_restart1_model1='results_restart_oceannc_model1'
                   ncks -d time,0 FRECVATM_model2_01.nc toto.nc
                   ncdump -p 6,8 toto.nc > titi
                   sed --silent '/history/ !p' titi > $file_results_FRECVATM_end
		   file_diff_FRECVATM_toy1_toy2='diff_FRECVATM_toy_time_transformations_namcouple_5'
		   file_diff_restart1_toy1_toy2='diff_oceannc_restart_toy_time_transformations_namcouple_5'
		   diff $file_results_FRECVATM_end ${USER_RUNDIR}/work_toy_time_transformations_namcouple_5_Makefile_1_model1_1_model2_1/$file_results_FRECVATM_end > $file_diff_FRECVATM_toy1_toy2
                   diff $file_results_restart1_model1 ${USER_RUNDIR}/work_toy_time_transformations_namcouple_5_Makefile_1_model1_1_model2_1/$file_results_restart1_model1 > $file_diff_restart1_toy1_toy2
		   cp $file_diff_FRECVATM_toy1_toy2 ${USER_RUNDIR}/$file_diff_FRECVATM_toy1_toy2
                   cp $file_diff_restart1_toy1_toy2 ${USER_RUNDIR}/$file_diff_restart1_toy1_toy2
                   if [ -s ${USER_RUNDIR}/$file_diff_FRECVATM_toy1_toy2 ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb with FRECVATM for the toy time_transformations and ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
                   if [ -s ${USER_RUNDIR}/$file_diff_restart1_toy1_toy2 ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb with restart for the toy time_transformations and ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
		   fi
		fi
		if [ $casename == toy_grids_writing ]; then
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                   echo "Compare grids with written in grids.nc"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	           cd ${rundir}
                   #++++++++++++++++
                   echo "nogt grid in grids.nc, masks.nc areas.nc"
                   #++++++++++++++++
                   ncdump -p 6,8 -v nogt.lon grids.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/bggd/d' titi > toto
                   sed -e '/x_nogt/d' toto > titi
                   sed -e '/y_nogt/d' titi > toto
                   sed -e '/crn_nogt/d' toto > titi
                   sed -e '/double/d' titi > nogt_lon_all_grids
                   ncdump -p 6,8 -v nogt.lat grids.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/bggd/d' titi > toto
                   sed -e '/x_nogt/d' toto > titi
                   sed -e '/y_nogt/d' titi > toto
                   sed -e '/crn_nogt/d' toto > titi
                   sed -e '/double/d' titi > nogt_lat_all_grids
                   ncdump -p 6,8 -v nogt.clo grids.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/bggd/d' titi > toto
                   sed -e '/x_nogt/d' toto > titi
                   sed -e '/y_nogt/d' titi > toto
                   sed -e '/crn_nogt/d' toto > titi
                   sed -e '/double/d' titi > nogt_clo_all_grids
		   ncdump -p 6,8 -v nogt.cla grids.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/bggd/d' titi > toto
                   sed -e '/x_nogt/d' toto > titi
                   sed -e '/y_nogt/d' titi > toto
                   sed -e '/crn_nogt/d' toto > titi
                   sed -e '/double/d' titi > nogt_cla_all_grids
                   ncdump -p 6,8 -v nogt.msk masks.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/bggd/d' titi > toto
                   sed -e '/x_nogt/d' toto > titi
                   sed -e '/y_nogt/d' titi > toto
                   sed -e '/int/d'    toto > titi
                   sed -e '/double/d' titi > toto
                   sed -e '/coherent/d' toto > nogt_msk_all_masks
                   ncdump -p 6,8 -v nogt.srf areas.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/bggd/d' titi > toto
                   sed -e '/x_nogt/d' toto > titi
                   sed -e '/y_nogt/d' titi > toto
                   sed -e '/double/d' toto > nogt_srf_all_areas
                   #++++++++++++++++
                   echo "bggd grid in grids.nc, masks.nc areas.nc"
                   #++++++++++++++++
                   ncdump -p 6,8 -v bggd.lon grids.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/nogt/d' titi > toto
                   sed -e '/x_bggd/d' toto > titi
                   sed -e '/y_bggd/d' titi > toto
                   sed -e '/crn_bggd/d' toto > titi
                   sed -e '/double/d' titi > bggd_lon_all_grids
		   ncdump -p 6,8 -v bggd.lat grids.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/nogt/d' titi > toto
                   sed -e '/x_bggd/d' toto > titi
                   sed -e '/y_bggd/d' titi > toto
                   sed -e '/crn_bggd/d' toto > titi
                   sed -e '/double/d' titi > bggd_lat_all_grids
                   ncdump -p 6,8 -v bggd.clo grids.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/nogt/d' titi > toto
                   sed -e '/x_bggd/d' toto > titi
                   sed -e '/y_bggd/d' titi > toto
                   sed -e '/crn_bggd/d' toto > titi
                   sed -e '/double/d' titi > bggd_clo_all_grids
                   ncdump -p 6,8 -v bggd.cla grids.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/nogt/d' titi > toto
                   sed -e '/x_bggd/d' toto > titi
                   sed -e '/y_bggd/d' titi > toto
                   sed -e '/crn_bggd/d' toto > titi
                   sed -e '/double/d' titi > bggd_cla_all_grids
                   ncdump -p 6,8 -v bggd.msk masks.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/nogt/d' titi > toto
                   sed -e '/x_bggd/d' toto > titi
                   sed -e '/y_bggd/d' titi > toto
                   sed -e '/int/d'    toto > titi
                   sed -e '/double/d' titi > toto
                   sed -e '/coherent/d' toto > bggd_msk_all_masks
		   ncdump -p 6,8 -v bggd.frc masks.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/nogt/d' titi > toto
                   sed -e '/x_bggd/d' toto > titi
                   sed -e '/y_bggd/d' titi > toto
                   sed -e '/int/d'    toto > titi
                   sed -e '/double/d' titi > toto
                   sed -e '/coherent/d' toto > bggd_frc_all_masks
                   ncdump -p 6,8 -v bggd.srf areas.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/nogt/d' titi > toto
                   sed -e '/x_bggd/d' toto > titi
                   sed -e '/y_bggd/d' titi > toto
                   sed -e '/double/d' toto > bggd_srf_all_areas
                   #++++++++++++++++
                   echo "nogt grid in initial grid"
                   #++++++++++++++++
                   ncdump -p 6,8 -v nogt.lon grids_nogt.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_nogt/d' titi > toto
                   sed -e '/y_nogt/d' toto > titi
                   sed -e '/crn_nogt/d' titi > toto
                   sed -e '/double/d' toto > nogt_lon_ini_grids
                   ncdump -p 6,8 -v nogt.lat grids_nogt.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_nogt/d' titi > toto
                   sed -e '/y_nogt/d' toto > titi
                   sed -e '/crn_nogt/d' titi > toto
                   sed -e '/double/d' toto > nogt_lat_ini_grids
                   ncdump -p 6,8 -v nogt.clo grids_nogt.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_nogt/d' titi > toto
                   sed -e '/y_nogt/d' toto > titi
                   sed -e '/crn_nogt/d' titi > toto
                   sed -e '/double/d' toto > nogt_clo_ini_grids
		   ncdump -p 6,8 -v nogt.cla grids_nogt.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_nogt/d' titi > toto
                   sed -e '/y_nogt/d' toto > titi
                   sed -e '/crn_nogt/d' titi > toto
                   sed -e '/double/d' toto > nogt_cla_ini_grids
                   ncdump -p 6,8 -v nogt.msk masks_nogt.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_nogt/d' titi > toto
                   sed -e '/y_nogt/d' toto > titi
                   sed -e '/int/d'    titi > toto
                   sed -e '/double/d' toto > titi
                   sed -e '/coherent/d' titi > nogt_msk_ini_masks
                   ncdump -p 6,8 -v nogt.srf areas_nogt.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_nogt/d' titi > toto
                   sed -e '/y_nogt/d' toto > titi
                   sed -e '/double/d' titi > nogt_srf_ini_areas
                   #++++++++++++++++
                   echo "bggd grid in initial grid"
                   #++++++++++++++++
                   ncdump -p 6,8 -v bggd.lon grids_bggd.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_bggd/d' titi > toto
                   sed -e '/y_bggd/d' toto > titi
                   sed -e '/crn_bggd/d' titi > toto
                   sed -e '/double/d' toto > bggd_lon_ini_grids
                   ncdump -p 6,8 -v bggd.lat grids_bggd.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_bggd/d' titi > toto
                   sed -e '/y_bggd/d' toto > titi
                   sed -e '/crn_bggd/d' titi > toto
                   sed -e '/double/d' toto > bggd_lat_ini_grids
		   ncdump -p 6,8 -v bggd.clo grids_bggd.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_bggd/d' titi > toto
                   sed -e '/y_bggd/d' toto > titi
                   sed -e '/crn_bggd/d' titi > toto
                   sed -e '/double/d' toto > bggd_clo_ini_grids
                   ncdump -p 6,8 -v bggd.cla grids_bggd.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_bggd/d' titi > toto
                   sed -e '/y_bggd/d' toto > titi
                   sed -e '/crn_bggd/d' titi > toto
                   sed -e '/double/d' toto > bggd_cla_ini_grids
                   ncdump -p 6,8 -v bggd.msk masks_bggd.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_bggd/d' titi > toto
                   sed -e '/y_bggd/d' toto > titi
                   sed -e '/int/d'    titi > toto
                   sed -e '/double/d' toto > titi
                   sed -e '/coherent/d' titi > bggd_msk_ini_masks
                   ncdump -p 6,8 -v bggd.frc masks_bggd.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_bggd/d' titi > toto
                   sed -e '/y_bggd/d' toto > titi
                   sed -e '/int/d'    titi > toto
                   sed -e '/double/d' toto > titi
                   sed -e '/coherent/d' titi > bggd_frc_ini_masks
                   ncdump -p 6,8 -v bggd.srf areas_bggd.nc > toto
                   sed -e '/netcdf/d' toto > titi
                   sed -e '/x_bggd/d' titi > toto
                   sed -e '/y_bggd/d' toto > titi
                   sed -e '/double/d' titi > bggd_srf_ini_areas
		   file_diff_results_nogt_lon='diff_nogt_lon_with_ini_'${rundirname}
		   file_diff_results_nogt_lat='diff_nogt_lat_with_ini_'${rundirname}
		   file_diff_results_nogt_clo='diff_nogt_clo_with_ini_'${rundirname}
		   file_diff_results_nogt_cla='diff_nogt_cla_with_ini_'${rundirname}
		   file_diff_results_nogt_msk='diff_nogt_msk_with_ini_'${rundirname}
		   file_diff_results_nogt_srf='diff_nogt_srf_with_ini_'${rundirname}
		   diff nogt_lon_all_grids nogt_lon_ini_grids > $file_diff_results_nogt_lon
                   diff nogt_lat_all_grids nogt_lat_ini_grids > $file_diff_results_nogt_lat
                   diff nogt_clo_all_grids nogt_clo_ini_grids > $file_diff_results_nogt_clo
                   diff nogt_cla_all_grids nogt_cla_ini_grids > $file_diff_results_nogt_cla
                   diff nogt_msk_all_masks nogt_msk_ini_masks > $file_diff_results_nogt_msk
                   diff nogt_srf_all_areas nogt_srf_ini_areas > $file_diff_results_nogt_srf
		   cp $file_diff_results_nogt_lon ${USER_RUNDIR}/$file_diff_results_nogt_lon
                   cp $file_diff_results_nogt_lat ${USER_RUNDIR}/$file_diff_results_nogt_lat
		   cp $file_diff_results_nogt_clo ${USER_RUNDIR}/$file_diff_results_nogt_clo
		   cp $file_diff_results_nogt_cla ${USER_RUNDIR}/$file_diff_results_nogt_cla
		   cp $file_diff_results_nogt_msk ${USER_RUNDIR}/$file_diff_results_nogt_msk
		   cp $file_diff_results_nogt_srf ${USER_RUNDIR}/$file_diff_results_nogt_srf
		   file_diff_results_bggd_lon='diff_bggd_lon_with_ini_'${rundirname}
		   file_diff_results_bggd_lat='diff_bggd_lat_with_ini_'${rundirname}
		   file_diff_results_bggd_clo='diff_bggd_clo_with_ini_'${rundirname}
		   file_diff_results_bggd_cla='diff_bggd_cla_with_ini_'${rundirname}
		   file_diff_results_bggd_msk='diff_bggd_msk_with_ini_'${rundirname}
		   file_diff_results_bggd_frc='diff_bggd_frc_with_ini_'${rundirname}
		   file_diff_results_bggd_srf='diff_bggd_srf_with_ini_'${rundirname}
		   diff bggd_lon_all_grids bggd_lon_ini_grids > $file_diff_results_bggd_lon
                   diff bggd_lat_all_grids bggd_lat_ini_grids > $file_diff_results_bggd_lat
                   diff bggd_clo_all_grids bggd_clo_ini_grids > $file_diff_results_bggd_clo
                   diff bggd_cla_all_grids bggd_cla_ini_grids > $file_diff_results_bggd_cla
                   diff bggd_msk_all_masks bggd_msk_ini_masks > $file_diff_results_bggd_msk
                   diff bggd_frc_all_masks bggd_frc_ini_masks > $file_diff_results_bggd_frc
                   diff bggd_srf_all_areas bggd_srf_ini_areas > $file_diff_results_bggd_srf
                   cp $file_diff_results_bggd_lon ${USER_RUNDIR}/$file_diff_results_bggd_lon
                   cp $file_diff_results_bggd_lat ${USER_RUNDIR}/$file_diff_results_bggd_lat
                   cp $file_diff_results_bggd_clo ${USER_RUNDIR}/$file_diff_results_bggd_clo
                   cp $file_diff_results_bggd_cla ${USER_RUNDIR}/$file_diff_results_bggd_cla
                   cp $file_diff_results_bggd_msk ${USER_RUNDIR}/$file_diff_results_bggd_msk
                   cp $file_diff_results_bggd_frc ${USER_RUNDIR}/$file_diff_results_bggd_frc
                   cp $file_diff_results_bggd_srf ${USER_RUNDIR}/$file_diff_results_bggd_srf
		   if [ -s ${USER_RUNDIR}/$file_diff_results_nogt_lon ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb nogt lon for the toy ${rundirname}" 
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_results_nogt_lat ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb nogt lat for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
                   if [ -s ${USER_RUNDIR}/$file_diff_results_nogt_clo ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb nogt clo for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_results_nogt_cla ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb nogt clo for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_results_nogt_msk ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb nogt msk for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_results_nogt_srf ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb nogt srf for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_results_bggd_lon ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb bggd lon for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_results_bggd_lat ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb bggd lat for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_results_bggd_clo ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb bggd clo for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_results_bggd_cla ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb bggd cla for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_results_bggd_msk ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb bggd msk for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_results_bggd_frc ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb bggd frc for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
		   if [ -s ${USER_RUNDIR}/$file_diff_results_bggd_srf ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb bggd srf for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
	        fi   
		if [ $casename == toy_load_balancing ]; then
                   cd ${rundir}
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                   echo "Verify that load balancing files are created"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                   ls timeline_*.nc
                   res_command=`echo $?` 
                   if [ ${res_command} -ne 0 ]; then
                      echo "timeline NetCDF files not created"
                      exit 1
                   fi
                fi
		if [ $casename == toy_mapcons ]; then
                   cd ${rundir}
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                   echo "Compare the correction factors applied in CONSERV method"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                   file_results_factors_conserv='results_factors_conserv'
                   file_diff_results_factors_conserv='diff_res_factors_conserv_'${rundirname}
		   grep 'DEBUG conserve' debug* > $file_results_factors_conserv 
		   diff $file_results_factors_conserv ${DIR_RES_REF}/${rundirname}/$file_results_factors_conserv > $file_diff_results_factors_conserv
                   ls $file_diff_results_factors_conserv
                   cp $file_diff_results_factors_conserv ${USER_RUNDIR}/$file_diff_results_factors_conserv
		   if [ -s ${USER_RUNDIR}/$file_diff_results_factors_conserv ]; then
                      echo "-------------------------------------------------------------------"
                      echo "WARNING : pb conserv factors for the toy ${rundirname}"
                      echo "-------------------------------------------------------------------"
                      exit 1
                   fi
	        fi   
        done
	(( nbtoy=nbtoy+1 ))
done
###############################################
###############################################
