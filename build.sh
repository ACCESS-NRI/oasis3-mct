#!/bin/bash

PROGNAME="$( basename ${BASH_SOURCE[0]} )"
PROJDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
PLATFORM="ubuntu"

if hostname --fqdn | grep gadi.nci.org.au$ > /dev/null
then
	# TODO: On gadi, should we execute this here or is it the callers
	#       responsibility?
	module purge
	module load intel-compiler-llvm/2025.0.4
	module load netcdf/4.9.2p
	# NOTE: The version of netcdf and netcdf-fortran may be different:
	# /apps/netcdf/4.7.4/lib/Intel/pkgconfig/netcdf-fortran.pc
	# Name: netcdf-fortran
	# ...
	# Version: 4.5.2
	module prepend-path PKG_CONFIG_PATH "${NETCDF_BASE}/lib/Intel/pkgconfig/"
	module load openmpi/5.0.5
	module load autoconf/2.72
	autoconf --version
	module list
	PLATFORM="nci"

	# The configure script checks for the presence of env var AR, RANLIB
	# and if not present, unilaterally sets AR=ar cq -> which isn't
	# a bad choice, but with oneAPI and link-time-optimisation, the
	# standard AR will not be able to make sense of object files
	# with the LTO-info. Required AR in the presence of LTO is llvm-ar;
	# but llvm-ar can always be used -> hence switching the default
	# to llvm-ar. However, this fix is only to prevent configure
	# from auto-populating; we also need to set AR again from the
	# relevant platform file (say `make.nci`).
	# Note that we are removing the `cq` flag from AR, which means
	# that two lib/mct/[mct,mpeu]/Makefile have `cq` hardcoded into
	# them (and ignore $ARFLAGS set in `make.nci`).
	# I had to remove the `cq` flag from AR because otherwise ``libscrip``
	# which honours ARFLAGS crashes - because the invocation is
	#	`llvm-ar cq rvD ...` and llvm-ar crashes because of the two sets of flags.
	# RANLIB is probably not necessary but included here for completeness.
	# Manodeep Sinha - 21 Mar, 2025
	export AR=`ifx --print-prog-name=llvm-ar`
	echo "ARCHIVER (AR) = " $AR
	# export RANLIB=`ifx --print-prog-name=llvm-ranlib`
fi

# See doc/oasis3mct_UserGuide.pdf:
#
# compiles all OASIS3-MCT libraries mct, scrip and psmile:
# make -f TopMakefileOasis3
#
# removes all OASIS3-MCT compiled sources and librairies:
# make realclean -f TopMakefileOasis3

cd ${PROJDIR}/util/make_dir && \
echo "include ${PROJDIR}/util/make_dir/make.${PLATFORM}" > make.inc && \
OASIS_HOME=${PROJDIR} make -f TopMakefileOasis3 realclean && \
OASIS_HOME=${PROJDIR} make -j$(nproc) -f TopMakefileOasis3
