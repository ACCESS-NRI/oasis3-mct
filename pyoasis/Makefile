%.o: %.mod

PYOASIS=$(COUPLE)/pyoasis

SRC_C = $(PYOASIS)/src/c
SRC_F = $(PYOASIS)/src/fortran_isoc

FFLAGS = $(F90FLAGS) $(DYNOPT) -I$(LIBBUILDDYN)/mct -I$(LIBBUILDDYN)/psmile.MPI1
CFLAGS = $(CCFLAGS) $(DYNOPT) -I$(SRC_C)

LFLAGS = $(LDFLAGS) $(DYNOPT) $(LDDYNOPT) -L$(ARCHDIR)/lib $(NETCDF4_LIBRARY)

PREFIX=$(HOME)/INSTALL/PyOasis


all: lib

lib: $(ARCHDIR)/lib/libpyoasiscore.so 

OBJS_F = pyoasis.o mod_oasis_auxiliary_routines_iso.o mod_oasis_getput_interface_iso.o mod_oasis_method_iso.o mod_oasis_part_iso.o mod_oasis_sys_iso.o mod_oasis_var_iso.o

OBJS_C = mod_oasis_auxiliary_routines_c.o mod_oasis_getput_interface_c.o mod_oasis_method_c.o mod_oasis_part_c.o mod_oasis_sys_c.o mod_oasis_var_c.o

$(ARCHDIR)/lib/libpyoasiscore.so: $(OBJS_F) $(OBJS_C)
	$(F90) $(LFLAGS) $(OBJS_F) $(OBJS_C) -lpsmile.$(CHAN) -lscrip -lsparsematrix -o $(ARCHDIR)/lib/libpyoasiscore.so


# C

mod_oasis_part_c.o: $(SRC_C)/mod_oasis_part_c.h $(SRC_C)/mod_oasis_part_c.c
	$(CC) $(CFLAGS) -c $(SRC_C)/mod_oasis_part_c.c

mod_oasis_var_c.o: $(SRC_C)/mod_oasis_var_c.h $(SRC_C)/mod_oasis_var_c.c
	$(CC) $(CFLAGS) -c $(SRC_C)/mod_oasis_var_c.c

mod_oasis_getput_interface_c.o: $(SRC_C)/mod_oasis_getput_interface_c.h $(SRC_C)/mod_oasis_getput_interface_c.c
	$(CC) $(CFLAGS) -c $(SRC_C)/mod_oasis_getput_interface_c.c

mod_oasis_auxiliary_routines_c.o: $(SRC_C)/mod_oasis_auxiliary_routines_c.h $(SRC_C)/mod_oasis_auxiliary_routines_c.c
	$(CC) $(CFLAGS) -c  $(SRC_C)/mod_oasis_auxiliary_routines_c.c

mod_oasis_sys_c.o: $(SRC_C)/mod_oasis_sys_c.h $(SRC_C)/mod_oasis_sys_c.c
	$(CC) $(CFLAGS) -c  $(SRC_C)/mod_oasis_sys_c.c

mod_oasis_method_c.o: $(SRC_C)/mod_oasis_method_c.h $(SRC_C)/mod_oasis_method_c.c
	$(CC) $(CFLAGS) -c  $(SRC_C)/mod_oasis_method_c.c


# ISO C Fortran

mod_oasis_getput_interface_iso.o: $(SRC_F)/mod_oasis_getput_interface_iso.F90 
	$(F90) $(FFLAGS) -c $(SRC_F)/mod_oasis_getput_interface_iso.F90

mod_oasis_var_iso.o: $(SRC_F)/mod_oasis_var_iso.F90 
	$(F90) $(FFLAGS) -c  $(SRC_F)/mod_oasis_var_iso.F90

mod_oasis_part_iso.o: $(SRC_F)/mod_oasis_part_iso.F90 
	$(F90) $(FFLAGS) -c  $(SRC_F)/mod_oasis_part_iso.F90

mod_oasis_auxiliary_routines_iso.o: $(SRC_F)/mod_oasis_auxiliary_routines_iso.F90
	$(F90) $(FFLAGS) -c  $(SRC_F)/mod_oasis_auxiliary_routines_iso.F90

mod_oasis_sys_iso.o: $(SRC_F)/mod_oasis_sys_iso.F90 
	$(F90) $(FFLAGS) -c  $(SRC_F)/mod_oasis_sys_iso.F90

mod_oasis_method_iso.o: $(SRC_F)/mod_oasis_method_iso.F90
	$(F90) $(FFLAGS) -c $(SRC_F)/mod_oasis_method_iso.F90

pyoasis.o: $(SRC_F)/pyoasis.F90
	$(F90) $(FFLAGS) -c $(SRC_F)/pyoasis.F90
	cp pyoasis.mod $(LIBBUILDDYN)/psmile.MPI1


# Clean
clean:
	rm -f *.o modules/*.mod *.so 
	rm -f oasis/lib/*.so
	rm -f oasis/src/psmile/*.o
	rm -f oasis/src/scrip/*.o
	rm -f oasis/src/sparsematrix/*.o
	rm -f $(SRC_F)/*.o
	rm -f $(SRC_F)/pyoasis.mod
	rm -f $(SRC_C)/*.o
	rm -f $(SRC_C)/libpyoasiscore.so


# Installation

install: lib
	@cp -f -p pyoasis.mod $(ARCHDIR)/mod
	@cp -f -p $(PYOASIS)/src/python/*.py $(ARCHDIR)/python


# Test

test: wrappertest completetest

wrappertest: wrappertest
	cd $(PYOASIS)/tests && pytest

completetest: 
	cd $(PYOASIS)/tests/apple_and_orange/ && bash run.sh
