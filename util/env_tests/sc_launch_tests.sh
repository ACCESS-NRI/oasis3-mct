#!/bin/ksh
#set -xv

### 0. Machine (see sc_top.sh)
#OASIS_ENV=tioman_intel21.1.1_intelmpi2021.1.1
#OASIS_ENV=nemo_intel18.0.1.163_intelmpi2018.1.163
#OASIS_ENV=scylla_intel2018.4.274_intelmpi2018.4.274
#OASIS_ENV=belenos_intel2018.5.274_intelmpi2018.5.274
#OASIS_ENV=stiff_pgi20.4_openmpi3.1.3 
#OASIS_ENV=fundy_gfortran10.2.0_openmpi4.1.0
#OASIS_ENV=kraken_intel18.0.1.163_intelmpi2018.1.163

export username=`whoami`
export host=`uname -n`
export batchmin=1

if [ -z "${OASIS_ENV}" ]; then
  echo "ERROR OASIS_ENV not defined"
  exit -9
fi

if [ -z "${OASIS_COUPLE}" ]; then
  echo "ERROR OASIS_COUPLE not defined"
  exit -9
fi

if [ -z "${OASIS_SUBMITWAIT}" ]; then
  submitwait=0
else
  submitwait=${OASIS_SUBMITWAIT}
fi
echo "submitwait = ${submitwait}"

######################################################################
### 1. Compute some case information about the model(s)
###    Supports up to 5 executables, more could be added easily

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
	  #echo " nmod : " ${nmod}
    if [ ${#models[@]} == 0 ]; then
	  #echo " ${#models[@]} : " ${#models[@]}
      models=(${nmod})
      pecnts=(${npes})
    else
	  #echo " ${#models[@]} : " ${#models[@]}
      models+=(${nmod})
      pecnts+=(${npes})
    fi
  fi
  #echo 'debug Num of Models: '${#models[@]}
  #echo 'debug Models       : '${models[@]}
  #echo 'debug pecnts       : '${pecnts[@]}
done

nproc=0
mpistr=''
for imodel in {1..${#models[@]}}
do
  let im=${imodel}-1
  if [ ${nproc} == 0 ]; then 
    if [ ${OASIS_ENV} == stiff_pgi20.4_openmpi3.1.3 ] || [ ${OASIS_ENV} == fundy_gfortran10.2.0_openmpi4.1.0 ]; then
       mpistr="${mpistr} -oversubscribe -n ${pecnts[$im]} ./${models[$im]}"
    else
       mpistr="${mpistr} -n ${pecnts[$im]} ./${models[$im]}"
    fi
  else
       mpistr="${mpistr} : -n ${pecnts[$im]} ./${models[$im]}"
  fi
  let nproc=nproc+${pecnts[$im]}
done
#echo "debug nproc = $nproc"
#echo "debug mpistr = $mpistr"

let nodes=$nproc/$corespn
let reste=$nproc-($nodes*$corespn)
if [[ $reste -ge $corespn ]]; then
  echo "error in nodes computation abort"
  exit -9
fi 
if [[ $reste -gt 0 ]]; then
 let nodes=$nodes+1
fi
#echo "debug nodes = ${nodes}"

if [ "${batchnhour:-unset}" == "unset" ]; then
  let batchhour=0
  if [ "${batchmin:-unset}" == "unset" ]; then
    let batchmin=20
  fi
else
  if [ "${batchmin:-unset}" == "unset" ]; then
    let batchmin=0
  fi
fi
#echo "debug batchhour = ${batchhour}"
#echo "debug batchmin = ${batchmin}"

######################################################################
### 2. Document

rundirname="work_${casename}_${USER_NAMCOUPLE}_${USER_MAKEFILE}"
for imodel in {1..${#models[@]}}
do
  let im=${imodel}-1
  echo ${models[$im]}' runs on '${pecnts[$im]}' processes'
  rundirname="${rundirname}_${models[$im]}_${pecnts[$im]}"
done
export rundir=${USER_RUNDIR}/${rundirname}

echo ''
echo '-------------------------------------------------'
echo 'Casename     : '${casename}
echo 'Casedir      : '${toy}
echo 'Rundir       : '${rundir}
echo 'Username     : '${username}
echo 'Host         : '${host}
echo 'Architecture : '${OASIS_ENV}
echo 'Num of Models: '${#models[@]}
echo 'Models       : '${models[@]}
echo 'pecnts       : '${pecnts[@]}
echo 'nproc        : '${nproc}
echo 'corespn      : '${corespn}
echo 'nodes        : '${nodes}
echo 'batchhour    : '${batchhour}
echo 'batchmin     : '${batchmin}
echo '-------------------------------------------------'
echo ''

######################################################################
### 3. Copy binaries and data into rundir
export rmrundir=true

if [ "${rmrundir:-unset}" != "unset" ]; then
  if [ "${rmrundir}" == "true" ]; then
    echo 'Deleting the current rundir'
    rm -r -f $rundir
  fi
fi
mkdir -p $rundir

echo "OASIS_COUPLE : ${OASIS_COUPLE}"
echo "OASIS_ENV : ${OASIS_ENV}"
echo "USER_NAMLOC : ${USER_NAMLOC}"
echo "USER_MAKELOC : ${USER_MAKELOC}"
echo "rundir : ${rundir}"

cp -f ${OASIS_COUPLE}/util/make_dir/comp_env_${OASIS_ENV}.sh ${rundir}/comp_env.sh
cp -f ${USER_NAMLOC}/${USER_NAMCOUPLE} ${rundir}/namcouple
cp -f ${USER_MAKELOC}/${USER_MAKEFILE} ${rundir}/Makefile
if [ -z ${USER_RSTLOC} ]; then
   echo "No restart file for this toy"
else
   cp ${USER_RSTLOC}/*.nc ${rundir}/.
fi
if [ -z ${USER_AUXLOC} ]; then
   echo "No auxiliary files for this toy"
else
   cp ${USER_AUXLOC}/grids.nc ${rundir}/grids.nc
   cp ${USER_AUXLOC}/areas.nc ${rundir}/areas.nc
   cp ${USER_AUXLOC}/masks.nc ${rundir}/masks.nc
fi
if [ -z ${USER_MESHLOC} ]; then
   echo "No model files for this toy"
else
   cp ${USER_MESHLOC}/*.nc ${rundir}/.
fi
if [ -z ${USER_RMPLOC} ]; then
   echo "No remapping file used with this toy"
else
   cp ${USER_RMPLOC}/*.nc ${rundir}/.
fi

if [ -z "${USER_SCRIPT}" ]; then
  user_script=0
else
  user_script=1
fi
echo "user_script = ${user_script}"
if [ ${user_script} == 1 ]; then
	${USER_SCRIPT}/sc_oasis_${casename}.sh
fi

for imodel in {1..${#models[@]}}
do
  let im=${imodel}-1
  cp -f ${pathname}/${casename}/${models[$im]} $rundir/.
  res_command=`echo $?`
  if [ ${res_command} -ne 0 ]; then
     echo "${models[$im]} not created"
     exit 1
  fi
done

cd $rundir

######################################################################
### 4. Creation of configuration scripts

###---------------------------------------------------------------------
### NEMO_LENOVO_INTELMPI_MPICH
###---------------------------------------------------------------------
if [ ${OASIS_ENV} == nemo_intel18.0.1.163_intelmpi2018.1.163 ]; then

  cat <<EOF > $rundir/run_$casename
#!/bin/bash -l
# Nom du job
#SBATCH --job-name ${casename}
# Temps limite du job
#SBATCH --time=${batchhour}:${batchmin}:00
#SBATCH --output=$rundir/$casename.o
#SBATCH --error=$rundir/$casename.e
# Nombre de noeuds et de processus
#SBATCH --nodes=${nodes} --ntasks-per-node=${corespn}
#SBATCH --distribution cyclic

cd $rundir

ulimit -s unlimited
. ./comp_env.sh
module list
#
#
time mpirun ${mpistr}
#
EOF
###---------------------------------------------------------------------
### SCYLLA_INTEL_INTELMPI 
###---------------------------------------------------------------------
elif [ ${OASIS_ENV} == scylla_intel2018.4.274_intelmpi2018.4.274 ]; then

  cat <<EOF > $rundir/run_$casename
#!/bin/bash -l
# Nom du job
#SBATCH --job-name ${casename}
# Temps limite du job
#SBATCH --partition amdgpu
#SBATCH --job-name ${casename}
#SBATCH --output=$rundir/$casename.o
#SBATCH --error=$rundir/$casename.e
# Nombre de noeuds et de processus
#SBATCH --nodes=${nodes} --ntasks-per-node=${corespn}
cd $rundir

ulimit -s unlimited
. ./comp_env.sh
module list
#
#
time mpirun ${mpistr}
#
EOF
###---------------------------------------------------------------------
### KRAKEN_INTEL_INTELMPI 
###---------------------------------------------------------------------
elif [ ${OASIS_ENV} == kraken_intel18.0.1.163_intelmpi2018.1.163 ]; then

	  cat <<EOF > $rundir/run_$casename
#!/bin/bash -l
#SBATCH --partition prod
# Nom du job
#SBATCH --job-name $casename
# Temps limite du job
#SBATCH --time=00:30:00
#SBATCH --output=$rundir/$casename.o
#SBATCH --error=$rundir/$casename.e
# Nombre de noeuds et de processus
#SBATCH --nodes=$nodes --ntasks-per-node=$corespn
#SBATCH --distribution cyclic

cd $rundir

ulimit -s unlimited
. ./comp_env.sh
module list
#
#
time mpirun ${mpistr}
#
EOF
###---------------------------------------------------------------------
### BELENOS_INTEL_INTELMPI ON AMD nodes
###---------------------------------------------------------------------
elif [ ${OASIS_ENV} == belenos_intel2018.5.274_intelmpi2018.5.274 ]; then

  cat <<EOF > $rundir/run_$casename
#!/bin/bash
# Nom du job
#SBATCH --job-name $casename
# Time limit for the job
#SBATCH --time=00:30:00
#SBATCH --partition=normal256        # partition/queue
#SBATCH --nodes=$nodes --ntasks-per-node=${corespn} # number of nodes and  number of procs
#SBATCH --output=$rundir/job.out%j
#SBATCH --error=$rundir/job.err%j

cd $rundir

ulimit -s unlimited
. ./comp_env.sh
module list
#
#
time mpirun ${mpistr}
#
EOF
###---------------------------------------------------------------------
### NEW COMPUTER
###---------------------------------------------------------------------
fi 

#tcx
#if [[ 1 == 0 ]]; then

######################################################################
### 5. Execute/Submit the model

if [ ${OASIS_ENV} == tioman_intel21.1.1_intelmpi2021.1.1 ] || [ ${OASIS_ENV} == stiff_pgi20.4_openmpi3.1.3 ] || [ ${OASIS_ENV} == fundy_gfortran10.2.0_openmpi4.1.0 ]; then
    echo "Executing the model using "`which mpirun`
    echo "${mpistr}"
    . ./comp_env.sh
    $MPIRUN ${mpistr} > runjob.err
elif [ ${OASIS_ENV} == scylla_intel2018.4.274_intelmpi2018.4.274 ] ; then
    echo 'Submitting the job to queue using sbatch'
    sbatch $rundir/run_$casename
    squeue -u $username
    if [ ${submitwait} -ne 0 ]; then
      texist=0
      file='out_qstat_run_'$casename
      while [ $texist == 0 ] ; do
        squeue -u $USER > $file
        lines=`wc -l < $file`
        echo "nb lines in $file $lines"
        if [ $lines == 1 ]; then
          texist=1
        else
          echo "Waiting for running ending..."
          sleep 10
        fi
      done
    fi
elif [ ${OASIS_ENV} == belenos_intel2018.5.274_intelmpi2018.5.274 ] || [ ${OASIS_ENV} == nemo_intel18.0.1.163_intelmpi2018.1.163 ] || [ ${OASIS_ENV} == kraken_intel18.0.1.163_intelmpi2018.1.163 ]; then
    echo 'Submitting the job to queue using sbatch'
    sbatch $rundir/run_$casename
    squeue -u $username
    if [ ${submitwait} -ne 0 ]; then
      texist=0
      file='out_qstat_run_'$casename
      while [ $texist == 0 ] ; do
        squeue -u $USER > $file
        lines=`wc -l < $file`
        echo "nb lines in $file $lines"
        if [ $lines == 1 ]; then
          texist=1
        else
          echo "Waiting for running ending..."
          sleep 30
        fi
      done
    fi
fi

if [ ${submitwait} -ne 0 ]; then
  cd $rundir
  grep -i 'MPI_Finalize' debug.* > res_end
  grep -i 'SUCCESSFUL RUN' debug.* >> res_end
  cat res_end
  echo "++++++++++++++++++++++++++++++++++++++++"
fi
echo "++++++++++++++++++++++++++++++++++++++++"

exit
######################################################################

#tcx
#fi
