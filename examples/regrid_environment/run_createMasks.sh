#!/bin/sh
#set -x

#++++++++++++++++++++++++++++++++++++++
# To set up a consistent atmosphere-ocean system and have a well-posed coupled problem, 
# the atmospheric mask is created from the ocean mask for one regridder.
# The original sea-land mask of the ocean model is taken as it is. 
# For the atmospheric model, the fraction of water in each cell is obtained by the conservative remapping 
# of the ocean mask on the atmospheric grid performed with the specified regridder.
# Then, the atmospheric coupling mask is created associating a valid/active index to cells containing at least 
# a surface fraction of water of 1/1000 (parameter water_thresh in src/model1.F90).
# Under this threshold of water, the atmospheric cell is considered completly masked.
# Note that masked atmospheric cells will then have nul ocean fractions.
#
# To create such binary and fractional atmospheric masks use:
#
# ./run_createMasks.sh ogrid agrid nnodes_nprocs_nthreads library [-plot]
# where
# 'ogrid' is the ocean grid
# 'agrid' is the atmospheric grid
# 'nnodes' the total number of nodes for the run,
# 'nprocs' the number of MPI tasks per node,
# 'nthreads' the number of OpenMP threads per MPI task,
# 'library' is the regridder used (either SCRP, ESMF or XIOS),
# '-plot' is an optional argument to plot the binary and fractional masks with Ferret.
#
# G. Jonville - 09/2022
#++++++++++++++++++++++++++++++++++++++

## - Define paths
srcdir=`pwd`
oasisdir=$srcdir/OASIS
xiosdir=$srcdir/XIOS
esmfdir=$srcdir/ESMF
casename=`basename $srcdir`

## - Define case
if [ $# -eq 0 ] ; then
    echo -e "\nBy default, i.e. without arguments, this script build the binary and fractional masks for the bggd grid coherent with the nogt grid with the SCRIP library;"
    echo -e "1 node, 1 MPI task and 1 OpenMP thread are used for the run, without plotting the created masks."
    echo -e "i.e. ./run_createMasks.sh nogt bggd 1_1_1 SCRP\n"
    og="nogt" ; ag="bggd" ; n_p_t=1_1_1 ; nnode=1 ; mpiprocs=1 ; threads=1 ; library=SCRP
elif [ $# -lt 4 ] || [ $# -gt 5 ] ; then
    echo -e "\nIf you don't want to run the default case, i.e. without arguments, "
    echo "you must run the script with 4 or 5 arguments:"
    echo "./run_createMasks.sh  ogrid agrid nnodes_nprocs_nthreads library [-plot]"
    echo -e "where \n'ogrid' is the ocean grid,\n'agrid is the atmospheric grid,'"
    echo -e "'nnodes' the total number of nodes for the run, \n'nprocs' the number of MPI tasks per node,"
    echo "'nthreads' the number of OpenMP threads per MPI task,"
    echo -e "'library' is the regridder used (either SCRP, ESMF or XIOS),"
    echo -e "'-plot' is an optional argument to plot the binary and fractional masks with Ferret."
    echo -e "Example: ./run_createMasks.sh torc icos 1_2_18 SCRP -plot\n"
    exit
else
    og=$1 ; ag=$2 ; n_p_t=$3 ; library=$4 ; todo=$5
    nnode=`echo $n_p_t | awk -F _ '{print $1}'`
    mpiprocs=`echo $n_p_t | awk -F _ '{print $2}'`
    threads=`echo $n_p_t | awk -F _ '{print $3}'`
fi
nproces=`echo $(($nnode*$mpiprocs))`
remap=conserv1st # => remapping method will be conservative 1st order destarea
ext=createMasks

## - Check library
if [ ${library} != "SCRP" ] && [ ${library} != "ESMF" ] && [ ${library} != "XIOS" ]; then
    echo -e "\nRemapping library must be either SCRP (for SCRIP), ESMF or XIOS\n"
    exit
fi
## - Create the masks output directory
masksdir="${oasisdir}/${library^^}_createdMasks"
mkdir -p $masksdir

## - Select ocean mask function "Fmask" (if not already the case) and rebuild model1
cd $srcdir/src
grep "^CPPKEY_FANA=Fmask" Makefile > /dev/null
if [ $? != 0 ]; then
    sed -i "s/^CPPKEY_FANA=.*/CPPKEY_FANA=Fmask # FANA1 FANA2 FANA3 Fmask/" Makefile
fi
make ; cd $srcdir

#++++++++++++++++++++++++++++++++++++++

## - Possibly manual selection of suites of ocean source grids and atmospheric target grids
##ogrids="torc" # "torc nogt"
##agrids="sse7" # "bggd icos sse7"
ogrids=$og
agrids=$ag

for ogrid in ${ogrids} ; do

   ## - Check ocean grid
   # nogt/torc is an ocean structured (LR) grid
   if [ ${ogrid} != "nogt" ] && [ ${ogrid} != "torc" ] && [ ${ogrid} != "t12e" ]; then
       echo "Source grid must be either nogt, torc, t12e"
       exit
   fi

   ## - Prepare the masks output file with the binary ocean mask
   masksfile="masks_${ogrid}_${library^^}.nc"
   ncks -h -A -v ${ogrid}.msk ${oasisdir}/masks_no_atm.nc ${masksdir}/${masksfile}

   for agrid in ${agrids} ; do

      ## - Check atmosphere grid
      # bggd is an atmosphere structured (LR) grid
      # icos/icoh is an atmosphere unstructured (U) grid
      # sse7 is an atmosphere gaussian reduced (D) grid
      if [ ${agrid} != "bggd" ] && [ ${agrid} != "sse7" ] && [ ${agrid} != "icos" ] && [ ${agrid} != "icoh" ]; then
          echo "Target grid must be either bggd, sse7, icos, icoh"
          exit
      fi

      if [ ${library} == "SCRP" ] || [ ${library} == "ESMF" ] || [ ${library} == "XIOS" ]; then

          # Compute library weights $ogrid-$agrid conserve_destarea.
          # Build the atmospheric mask by an OASIS remapping of binary ocean mask function from ocean grid to unmasked atmospheric grid
          ./run_regrid.sh $ogrid $agrid $remap $n_p_t $library $ext

      fi

      rundir=$srcdir/RUNDIR_${library}_${ext}/${casename}_${ogrid}_${agrid}_${remap}_${nnode}_${mpiprocs}_${threads}_${library}_${ext}

      ## - Waiting for the atmospheric mask file to continue
      while [ ! -f $rundir/mask_${agrid}_w${ogrid}.nc ]; do sleep 1; done

      # Copy the binary and fractional atmospheric masks coherent with the ocean mask in the masks file
      ncks -h -A -v ${agrid}.frc $rundir/frac_${agrid}_w${ogrid}.nc ${masksdir}/${masksfile}
      ncks -h -A -v ${agrid}.msk $rundir/mask_${agrid}_w${ogrid}.nc ${masksdir}/${masksfile}


      ## - Plot the binary and fractional atmospheric masks
      if [[ ${todo} = "-plot" ]]; then
          cd $rundir
          cat <<EOF >> plotex_mskfrc.jnl
go ${oasisdir}/plot_mskfrc.jnl $agrid $ogrid
!exit

EOF
          exferret < plotex_mskfrc.jnl
          echo -e "\nPlots are written in $masksdir \n"
          mv plot_${agrid}_????_w${ogrid}.gif $masksdir
          \rm -f plotex_mskfrc.jnl ferret.jnl
          cd $srcdir
      fi

   done
done

