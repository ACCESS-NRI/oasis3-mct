#
# System dependent settings 
#
# $Id: make.inc 1252 2007-02-28 13:37:54Z redler $
#
##### User configurable options #####
#
# Note: The absolute path name must be indicated.
#
# Note: Choose one of these includes files and modify it according to your
#       local settings. Replace the currently active file with your own.
#
#MAKE_PGI_OPENMPI_LINUX_include /space/coquart/oasis3-mct_buildbot/util/make_dir/make.pgi_openmpi_linux_buildbot
#MAKE_OPENMP_PGI_OPENMPI_LINUX_include /space/coquart/oasis3-mct_buildbot/util/make_dir/make.pgi_openmpi_openmp_linux_buildbot
#
#MAKE_PGI_MPICH_LINUX_include /space/coquart/oasis3-mct_buildbot/util/make_dir/make.pgi_mpich_linux_buildbot
#MAKE_OPENMP_PGI_MPICH_LINUX_include /space/coquart/oasis3-mct_buildbot/util/make_dir/make.pgi_mpich_openmp_linux_buildbot
#
#MAKE_GFORTRAN_OPENMPI_LINUX_include /space/coquart/oasis3-mct_buildbot/util/make_dir/make.gfortran_openmpi_linux_buildbot
include /space/coquart/oasis3-mct_buildbot/util/make_dir/make.gfortran_openmpi_openmp_linux_buildbot
#
#MAKE_NEMO_LENOVO_GFORTRAN_OPENMPI_include /scratch/globc/${USER}/OASIS3_BUILDBOT/oasis3-mct_buildbot/util/make_dir/make.gfortran_openmpi_nemo_lenovo_buildbot
#MAKE_OPENMP_NEMO_LENOVO_GFORTRAN_OPENMPI_include /scratch/globc/${USER}/OASIS3_BUILDBOT/oasis3-mct_buildbot/util/make_dir/make.gfortran_openmpi_nemo_lenovo_openmp_buildbot
#
#MAKE_NEMO_LENOVO_INTEL_IMPI_include /scratch/globc/${USER}/OASIS3_BUILDBOT/oasis3-mct_buildbot/util/make_dir/make.intel_impi_nemo_lenovo_buildbot
#MAKE_OPENMP_NEMO_LENOVO_INTEL_IMPI_include /scratch/globc/${USER}/OASIS3_BUILDBOT/oasis3-mct_buildbot/util/make_dir/make.intel_impi_nemo_lenovo_openmp_buildbot
#
#MAKE_BEAUFIX_include /scratch/work/cglo355/oasis3-mct_buildbot/util/make_dir/make.beaufix_intel_impi_buildbot
#MAKE_OPENMP_BEAUFIX_INTEL_IMPI_include /scratch/work/cglo355/oasis3-mct_buildbot/util/make_dir/make.beaufix_intel_impi_openmp_buildbot
#
#MAKE_GIEC6_include /scratch/globc/giec6/TESTS_LAURE/OASIS3-MCT_3.0/util/make_dir/make.intel_nemo_lenovo_giec6
#
#
### End User configurable options ###
