%.o: %.mod 

PREFIX=${HOME}/opt
OASIS=${HOME}/oasis3-mct/
PYOASIS=${OASIS}/pyoasis
MODULES=${PYOASIS}/oasis/modules

FC=mpif90
CC=mpicc
CXX=mpic++
FFLAGS=-fPIC -ffree-form -J${MODULES} 
CFLAGS=-fPIC -I/usr/include/python3.8
CPPFLAGS=-fPIC -I/usr/include/python3.8
LFLAGS=-L/home/igw26125/opt2/lib -L. -Loasis/lib -fPIC

all: liboasis libpyoasiscore.so 




libpyoasiscore.so: pyoasis.o mod_oasis_auxiliary_routines_iso.o mod_oasis_getput_interface_iso.o mod_oasis_method_iso.o mod_oasis_part_iso.o mod_oasis_sys_iso.o mod_oasis_var_iso.o mod_oasis_grid_iso.o mod_oasis_auxiliary_routines_c.o mod_oasis_getput_interface_c.o mod_oasis_method_c.o mod_oasis_part_c.o mod_oasis_sys_c.o mod_oasis_var_c.o mod_oasis_grid_c.o pyoasis.o
	${CC} mod_oasis_auxiliary_routines_iso.o\
              mod_oasis_getput_interface_iso.o\
              mod_oasis_method_iso.o\
              mod_oasis_part_iso.o\
              mod_oasis_sys_iso.o\
              mod_oasis_var_iso.o\
              mod_oasis_grid_iso.o\
              mod_oasis_auxiliary_routines_c.o\
              mod_oasis_getput_interface_c.o\
              mod_oasis_method_c.o\
              mod_oasis_part_c.o\
              mod_oasis_sys_c.o\
              mod_oasis_var_c.o\
              mod_oasis_grid_c.o\
              pyoasis.o\
              ${LFLAGS} -lpsmile.MPI1 -lscrip -lsparsematrix -shared -lnetcdf -lnetcdff -shared -o libpyoasiscore.so


# C
mod_oasis_grid_c.o: mod_oasis_grid_c.h mod_oasis_grid_c.c
	${CC} mod_oasis_grid_c.c -c ${CFLAGS}

mod_oasis_part_c.o: mod_oasis_part_c.h mod_oasis_part_c.c
	${CC} mod_oasis_part_c.c -c ${CFLAGS}

mod_oasis_oasis_var_c.o: mod_oasis_var_c.h mod_oasis_var_c.c
	${CC} mod_oasis_var_c.c -c ${CFLAGS}

mod_oasis_getput_interface_c.o: mod_oasis_getput_interface_c.h mod_oasis_getput_interface_c.c
	${CC} mod_oasis_getput_interface_c.c -c ${CFLAGS}

mod_oasis_auxiliary_routines_c.o: mod_oasis_auxiliary_routines_c.h mod_oasis_auxiliary_routines_c.c
	${CC} mod_oasis_auxiliary_routines_c.c -c ${CFLAGS}

mod_oasis_sys_c.o: mod_oasis_sys_c.h mod_oasis_sys_c.c
	${CC} mod_oasis_sys_c.c -c ${CFLAGS}

mod_oasis_method_c.o: mod_oasis_method_c.h mod_oasis_method_c.c
	${CC} mod_oasis_method_c.c -c ${CFLAGS}


# ISO C Fortran

mod_oasis_grid_iso.o: mod_oasis_grid_iso.F90 pyoasis.mod
	${FC} mod_oasis_grid_iso.F90 -c ${FFLAGS}

mod_oasis_getput_interface_iso.o: mod_oasis_getput_interface_iso.F90 pyoasis.mod
	${FC} mod_oasis_getput_interface_iso.F90 -c ${FFLAGS}

mod_oasis_var_iso.o: mod_oasis_var_iso.F90 pyoasis.mod
	${FC} mod_oasis_var_iso.F90 -c ${FFLAGS}

mod_oasis_part_iso.o: mod_oasis_part_iso.F90 pyoasis.mod
	${FC} mod_oasis_part_iso.F90 -c ${FFLAGS}

mod_oasis_auxiliary_routines_iso.o: mod_oasis_auxiliary_routines_iso.F90 pyoasis.mod
	${FC} mod_oasis_auxiliary_routines_iso.F90 -c ${FFLAGS}

mod_oasis_sys_iso.o: mod_oasis_sys_iso.F90 pyoasis.mod
	${FC} mod_oasis_sys_iso.F90 -c ${FFLAGS}

mod_oasis_method_iso.o: mod_oasis_method_iso.F90
	${FC} -c mod_oasis_method_iso.F90  ${FFLAGS}

pyoasis.o: pyoasis.F90
	${FC}  -c pyoasis.F90


# Shared libraries for OASIS
# Hack to change the source code to solve underscore issues and
# create shared libraries compiled with -fPIC
# Temporary solution till this is part of Oasis
# Defined flag use_comm_MPI1 because it is needed in
# mod_oasis_method.f90, at line 376

liboasis: oasis/lib/libpsmile.MPI1.so oasis/lib/libscrip.so oasis/lib/libsparsematrix.so

oasis/lib/libpsmile.MPI1.so:
	cd oasis/src/psmile &&\
	rm -f *.o *.so *.F90  &&\
	cp ${HOME}/compile_oa3-mct/build/lib/psmile.MPI1/mod_oasis.mod ${MODULES} &&\
	cp ${HOME}/compile_oa3-mct/build/lib/psmile.MPI1/*.mod ${MODULES} &&\
        cp ${HOME}/compile_oa3-mct/build/lib/mct/*.mod ${MODULES} &&\
	cp ${HOME}/compile_oa3-mct/build/lib/scrip/*.mod  ${MODULES} &&\
        cp ${HOME}/oasis3-mct/lib/psmile/src/*.F90 . &&\
	cp ${HOME}/oasis3-mct/lib/psmile/src/*.c . &&\
	cp shr_reprosumx86.c shr_reprosumx86_.c  &&\
	sed -i 's/shr_reprosumx86_fix_start/shr_reprosumx86_fix_start_/g' shr_reprosumx86_.c &&\
	sed -i 's/shr_reprosumx86_fix_end/shr_reprosumx86_fix_end_/g' shr_reprosumx86_.c &&\
	cp GPTLget_memusage.c GPTLget_memusage_.c &&\
	sed -i 's/gptlget_memusage_/gptlget_memusage/g' GPTLget_memusage_.c &&\
	${FC} *.F90 -c -Duse_comm_MPI1 -J${PYOASIS} -ext_names -ffree-line-length-512 -fPIC -I${OASIS}/lib/psmile/include &&\
	${CC} *.c -c -J${PYOASIS}  -fPIC -I${OASIS}/lib/psmile/include &&\
	${FC} ${LFLAGS} *.o -o ../../lib/libpsmile.MPI1.so -fPIC -shared -lnetcdf -lnetcdff

oasis/lib/libscrip.so:
	cd oasis/src/scrip &&\
	rm -f *.o *.so *.F90 *.h *.c &&\
        cp ${HOME}/compile_oa3-mct/build/lib/psmile.MPI1/mod_oasis.mod ${PYOASIS} &&\
	cp ${HOME}/oasis3-mct/lib/scrip/src/*.F90 . &&\
	cp ${HOME}/oasis3-mct/lib/scrip/src/*.f90 . &&\
	cp ${HOME}/oasis3-mct/lib/scrip/src/*.f . &&\
	cp ${HOME}/compile_oa3-mct/build/lib/scrip/*.mod ${MODULES} &&\
	cp ${HOME}/oasis3-mctold/lib/mct/config.h . &&\
	cp ${HOME}/oasis3-mct/lib/mct/mpeu/*.c . &&\
	${FC} *.F90 -c -Duse_comm_MPI1 -J${MODULES} -ffree-line-length-512 -fPIC &&\
	${FC} *.f90 -c -Duse_comm_MPI1 -J${MODULES} -ffree-line-length-512 -fPIC &&\
	${FC} *.f -c -Duse_comm_MPI1 -J${MODULES} -ffree-line-length-512 -fPIC &&\
	${CC} *.c -fPIC -c -I. &&\
	${FC} ${LFLAGS} *.o -o ../../lib/libscrip.so -fPIC -shared -lnetcdf -lnetcdff

oasis/lib/libsparsematrix.so:
	cd oasis/src/sparsematrix &&\
	rm -f *.o *.so *.F90 *.h *.c  &&\
        cp ${HOME}/compile_oa3-mct/build/lib/psmile.MPI1/mod_oasis.mod ${MODULES}  &&\
	cp ${HOME}/compile_oa3-mct/build/lib/psmile.MPI1/*.mod ${MODULES} &&\
        cp ${HOME}/compile_oa3-mct/build/lib/mct/*.mod ${MODULES} &&\
	cp ${HOME}/compile_oa3-mct/build/lib/scrip/*.mod ${MODULES} &&\
	cp ${HOME}/compile_oa3-mct/build/lib/mct/*.mod ${MODULES} &&\
	cp ${HOME}/compile_oa3-mct/build/lib/mct/*.mod ${MODULES} &&\
	cp ${HOME}/oasis3-mct/lib/mct/mpeu/*.F90 . &&\
	cp ${HOME}/oasis3-mct/lib/mct/mct/*.F90 .  &&\
	cp ${HOME}/compile_oa3-mct/build/lib/mctdir/config.h . &&\
	cp ${HOME}/oasis3-mct/lib/mct/mpeu/*.c . &&\
	${FC} *.F90 -c -Duse_comm_MPI1 -J${MODULES} -ffree-line-length-512 -fPIC &&\
	${CC} *.c -fPIC -c -I. &&\
	${FC} ${LFLAGS} *.o -o ../../lib/libsparsematrix.so -fPIC -shared


# Clean
clean:
	rm -f *.o modules/*.mod *.so 
	rm -f oasis/lib/*.so
	rm -f oasis/src/psmile/*.o
	rm -f oasis/src/scrip/*.o
	rm -f oasis/src/sparsematrix/*.o


# Installation

install:
	mkdir -p ${PREFIX}/include
	mkdir -p ${PREFIX}/lib
	mkdir -p ${PREFIX}/bin
	mkdir -p ${PREFIX}/modules
	cp -v oasis/lib/*.so ${PREFIX}/lib
	cp -v libpyoasiscore.so ${PREFIX}/lib
	cp -v *.py ${PREFIX}/modules
	cp -v *.mod oasis/modules
