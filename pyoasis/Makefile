%.o: %.mod

OASIS=${OASIS3_ROOT}
OASIS_INST=${HOME}/INSTALL/oasis3-mct
PYOASIS=${OASIS}/pyoasis

SRC_C=${PYOASIS}/src/c
SRC_F=${PYOASIS}/src/fortran_isoc

MODULES=${PYOASIS}/oasis/modules

FC=mpiifort
CC=mpiicc
CXX=mpiicpc
FFLAGS=-fPIC -I${MODULES} -I$(NETCDF4_INCDIR) -g -O2 
CFLAGS=-fPIC -I$(NETCDF4_INCDIR) -I/usr/include/python3.6m -g -O2
CPPFLAGS=-fPIC -I$(NETCDF4_INCDIR) -I/usr/include/python3.6m -g -O2
LFLAGS=-L${PYOASIS}/oasis/lib -L. -Loasis/lib -fPIC -L$(NETCDF4_LIBDIR) -L$(HDF5_LIBDIR)

PREFIX=${HOME}/INSTALL/PyOasis


all: liboasis ${SRC_C}/libpyoasiscore.so 


${SRC_C}/libpyoasiscore.so:${SRC_F}/pyoasis.o ${SRC_F}/mod_oasis_auxiliary_routines_iso.o ${SRC_F}/mod_oasis_getput_interface_iso.o ${SRC_F}/mod_oasis_method_iso.o ${SRC_F}/mod_oasis_part_iso.o ${SRC_F}/mod_oasis_sys_iso.o ${SRC_F}/mod_oasis_var_iso.o ${SRC_C}/mod_oasis_auxiliary_routines_c.o ${SRC_C}/mod_oasis_getput_interface_c.o ${SRC_C}/mod_oasis_method_c.o ${SRC_C}/mod_oasis_part_c.o ${SRC_C}/mod_oasis_sys_c.o ${SRC_C}/mod_oasis_var_c.o
	cd ${SRC_C} &&\
        ${CC} ../fortran_isoc/mod_oasis_auxiliary_routines_iso.o\
        ../fortran_isoc/mod_oasis_getput_interface_iso.o\
        ../fortran_isoc/mod_oasis_method_iso.o\
        ../fortran_isoc/mod_oasis_part_iso.o\
        ../fortran_isoc/mod_oasis_sys_iso.o\
        ../fortran_isoc/mod_oasis_var_iso.o\
        mod_oasis_auxiliary_routines_c.o\
        mod_oasis_getput_interface_c.o\
        mod_oasis_method_c.o\
        mod_oasis_part_c.o\
        mod_oasis_sys_c.o\
        mod_oasis_var_c.o\
        ../fortran_isoc/pyoasis.o\
        ${LFLAGS} -lpsmile.MPI1 -lscrip -lsparsematrix -shared -lnetcdff -lnetcdf -lhdf5 -shared -o libpyoasiscore.so


# C

${SRC_C}/mod_oasis_part_c.o: ${SRC_C}/mod_oasis_part_c.h ${SRC_C}/mod_oasis_part_c.c
	cd ${SRC_C} && ${CC} mod_oasis_part_c.c -c ${CFLAGS}

${SRC_C}/mod_oasis_oasis_var_c.o: ${SRC_C}/mod_oasis_var_c.h ${SRC_C}/mod_oasis_var_c.c
	cd ${SRC_C} && ${CC} mod_oasis_var_c.c -c ${CFLAGS}

${SRC_C}/mod_oasis_getput_interface_c.o: ${SRC_C}/mod_oasis_getput_interface_c.h ${SRC_C}/mod_oasis_getput_interface_c.c
	cd ${SRC_C} && ${CC} mod_oasis_getput_interface_c.c -c ${CFLAGS}

${SRC_C}/mod_oasis_auxiliary_routines_c.o: ${SRC_C}/mod_oasis_auxiliary_routines_c.h ${SRC_C}/mod_oasis_auxiliary_routines_c.c
	cd ${SRC_C} && ${CC} mod_oasis_auxiliary_routines_c.c -c ${CFLAGS}

${SRC_C}/mod_oasis_sys_c.o: ${SRC_C}/mod_oasis_sys_c.h ${SRC_C}/mod_oasis_sys_c.c
	cd ${SRC_C} && ${CC} mod_oasis_sys_c.c -c ${CFLAGS}

${SRC_C}/mod_oasis_method_c.o: ${SRC_C}/mod_oasis_method_c.h ${SRC_C}/mod_oasis_method_c.c
	cd ${SRC_C} && ${CC} mod_oasis_method_c.c -c ${CFLAGS}


# ISO C Fortran

${SRC_F}/mod_oasis_getput_interface_iso.o: ${SRC_F}/mod_oasis_getput_interface_iso.F90 
	cd ${SRC_F} && ${FC} mod_oasis_getput_interface_iso.F90 -c ${FFLAGS}

${SRC_F}/mod_oasis_var_iso.o: ${SRC_F}/mod_oasis_var_iso.F90 
	cd ${SRC_F} && ${FC} mod_oasis_var_iso.F90 -c ${FFLAGS}

${SRC_F}/mod_oasis_part_iso.o: ${SRC_F}/mod_oasis_part_iso.F90 
	cd ${SRC_F} && ${FC} mod_oasis_part_iso.F90 -c ${FFLAGS}

${SRC_F}/mod_oasis_auxiliary_routines_iso.o: ${SRC_F}/mod_oasis_auxiliary_routines_iso.F90
	cd ${SRC_F} && ${FC} mod_oasis_auxiliary_routines_iso.F90 -c ${FFLAGS}

${SRC_F}/mod_oasis_sys_iso.o: ${SRC_F}/mod_oasis_sys_iso.F90 
	cd ${SRC_F} && ${FC} mod_oasis_sys_iso.F90 -c ${FFLAGS}

${SRC_F}/mod_oasis_method_iso.o: ${SRC_F}/mod_oasis_method_iso.F90
	cd ${SRC_F} && ${FC} -c mod_oasis_method_iso.F90  ${FFLAGS}

${SRC_F}/pyoasis.o: ${SRC_F}/pyoasis.F90
	cd ${SRC_F} && ${FC} -c pyoasis.F90 ${FFLAGS}
	cp ${SRC_F}/pyoasis.mod ${MODULES}

# Shared libraries for OASIS
# Hack to change the source code to solve underscore issues and
# create shared libraries compiled with -fPIC
# Temporary solution till this is part of Oasis
# Defined flag use_comm_MPI1 because it is needed in
# mod_oasis_method.f90, at line 376

liboasis: oasis/lib/libpsmile.MPI1.so oasis/lib/libscrip.so oasis/lib/libsparsematrix.so

oasis/lib/libpsmile.MPI1.so:
	mkdir -p oasis/src/psmile &&\
	mkdir -p ${MODULES} &&\
	mkdir -p oasis/lib &&\
	cd oasis/src/psmile &&\
	rm -f *.o *.so *.F90  &&\
	cp ${OASIS_INST}/build/lib/psmile.MPI1/mod_oasis.mod ${MODULES} &&\
	cp ${OASIS_INST}/build/lib/psmile.MPI1/*.mod ${MODULES} &&\
        cp ${OASIS_INST}/build/lib/mct/*.mod ${MODULES} &&\
	cp ${OASIS_INST}/build/lib/scrip/*.mod  ${MODULES} &&\
        cp ${OASIS}/lib/psmile/src/*.F90 . &&\
	cp ${OASIS}/lib/psmile/src/*.c . &&\
	cp shr_reprosumx86.c shr_reprosumx86_.c  &&\
	sed -i 's/shr_reprosumx86_fix_start/shr_reprosumx86_fix_start_/g' shr_reprosumx86_.c &&\
	sed -i 's/shr_reprosumx86_fix_end/shr_reprosumx86_fix_end_/g' shr_reprosumx86_.c &&\
	cp GPTLget_memusage.c GPTLget_memusage_.c &&\
	sed -i 's/gptlget_memusage_/gptlget_memusage/g' GPTLget_memusage_.c &&\
	${FC} ${FFLAGS} *.F90 -c -Duse_comm_MPI1  -I${OASIS}/lib/psmile/include &&\
	${CC} ${CFLAGS} *.c -c -I${MODULES} -I${OASIS}/lib/psmile/include &&\
	${FC} ${LFLAGS} *.o -o ../../lib/libpsmile.MPI1.so -fPIC -shared -lnetcdff -lnetcdf -lhdf5

oasis/lib/libscrip.so:
	mkdir -p oasis/src/scrip &&\
	mkdir -p ${MODULES} &&\
	mkdir -p oasis/lib &&\
	cd oasis/src/scrip &&\
	rm -f *.o *.so *.F90 *.h *.c &&\
        cp ${OASIS_INST}/build/lib/psmile.MPI1/mod_oasis.mod ${PYOASIS} &&\
	cp ${OASIS}/lib/scrip/src/*.F90 . &&\
	cp ${OASIS}/lib/scrip/src/*.f90 . &&\
	cp ${OASIS}/lib/scrip/src/*.f . &&\
	cp ${OASIS_INST}/build/lib/scrip/*.mod ${MODULES} &&\
	cp ${OASIS_INST}/build/lib/mctdir/config.h . &&\
	cp ${OASIS}/lib/mct/mpeu/*.c . &&\
	${FC} ${FFLAGS} *.F90 -c -Duse_comm_MPI1  &&\
	${FC} ${FFLAGS} *.f90 -c -Duse_comm_MPI1  &&\
	${FC} ${FFLAGS} *.f -c -Duse_comm_MPI1  &&\
	${CC} ${CFLAGS} *.c -c -I. &&\
	${FC} ${LFLAGS} *.o -o ../../lib/libscrip.so -fPIC -shared -lnetcdff -lnetcdf -lhdf5

oasis/lib/libsparsematrix.so:
	mkdir -p oasis/src/sparsematrix &&\
	mkdir -p ${MODULES} &&\
	mkdir -p oasis/lib &&\
	cd oasis/src/sparsematrix &&\
	rm -f *.o *.so *.F90 *.h *.c  &&\
        cp ${OASIS_INST}/build/lib/psmile.MPI1/mod_oasis.mod ${MODULES}  &&\
	cp ${OASIS_INST}/build/lib/psmile.MPI1/*.mod ${MODULES} &&\
        cp ${OASIS_INST}/build/lib/mct/*.mod ${MODULES} &&\
	cp ${OASIS_INST}/build/lib/scrip/*.mod ${MODULES} &&\
	cp ${OASIS_INST}/build/lib/mct/*.mod ${MODULES} &&\
	cp ${OASIS_INST}/build/lib/mct/*.mod ${MODULES} &&\
	cp ${OASIS}/lib/mct/mpeu/*.F90 . &&\
	cp ${OASIS}/lib/mct/mct/*.F90 .  &&\
	cp ${OASIS_INST}/build/lib/mctdir/config.h . &&\
	cp ${OASIS}/lib/mct/mpeu/*.c . &&\
	${FC} ${FFLAGS} *.F90 -c -Duse_comm_MPI1  &&\
	${CC} ${CFLAGS} *.c -c -I. &&\
	${FC} ${LFLAGS} *.o -o ../../lib/libsparsematrix.so -fPIC -shared


# Clean
clean:
	rm -f *.o modules/*.mod *.so 
	rm -f oasis/lib/*.so
	rm -f oasis/src/psmile/*.o
	rm -f oasis/src/scrip/*.o
	rm -f oasis/src/sparsematrix/*.o
	rm -f ${SRC_F}/*.o
	rm -f ${SRC_F}/pyoasis.mod
	rm -f ${SRC_C}/*.o
	rm -f ${SRC_C}/libpyoasiscore.so


# Installation

install:
	mkdir -p ${PREFIX}/include
	mkdir -p ${PREFIX}/lib
	mkdir -p ${PREFIX}/bin
	mkdir -p ${PREFIX}/modules
	cp -v oasis/lib/*.so ${PREFIX}/lib
	cp -v ${SRC_F}/pyoasis.mod ${PREFIX}/modules
	cp -v ${SRC_C}/libpyoasiscore.so  ${PREFIX}/lib
	cp -v src/python/*.py ${PREFIX}/modules
	echo export PYOASIS_ROOT=${PREFIX} > init.sh
	echo export LD_LIBRARY_PATH=\$${PYOASIS_ROOT}/lib:\$${LD_LIBRARY_PATH} >> init.sh
	echo export PYTHONPATH=\$${PYOASIS_ROOT}/modules:\$${PYTHONPATH} >> init.sh
	@echo ======================================================
	@echo The following lines have been put in the file init.sh.
	@echo
	@cat init.sh
	@echo
	@echo The command \"source init.sh\" has to be be issued
	@echo before using pyOASIS. Alternatively, these lines
	@echo should be added to your \~/.bashrc file. 


# Test

test: wrappertest completetest

wrappertest: wrappertest
	cd tests && pytest

completetest: 
	cd tests/apple_and_orange/ && bash run.sh
