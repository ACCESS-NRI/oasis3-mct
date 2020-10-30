%.o: %.mod

PYOASIS=$(COUPLE)/pyoasis

SRC_C = $(PYOASIS)/src/c
SRC_F = $(PYOASIS)/src/fortran_isoc

FFLAGS = $(F90FLAGS) $(DYNOPT) -I$(LIBBUILDDYN)/mct -I$(LIBBUILDDYN)/psmile.$(CHAN)
CFLAGS = $(CCFLAGS) $(DYNOPT) -I$(SRC_C)

LFLAGS = $(LDFLAGS) $(DYNOPT) $(LDDYNOPT) -L$(ARCHDIR)/lib $(NETCDF_LIBRARY)

all: lib

lib: $(ARCHDIR)/lib/liboasis.C.bindings.so 

OBJS_F = cbindings.o mod_oasis_auxiliary_routines_iso.o mod_oasis_getput_interface_iso.o mod_oasis_method_iso.o mod_oasis_part_iso.o mod_oasis_sys_iso.o mod_oasis_var_iso.o

OBJS_C = mod_oasis_auxiliary_routines_c.o mod_oasis_getput_interface_c.o mod_oasis_method_c.o mod_oasis_part_c.o mod_oasis_sys_c.o mod_oasis_var_c.o

$(ARCHDIR)/lib/liboasis.C.bindings.so: $(OBJS_F) $(OBJS_C)
	$(F90) $(LFLAGS) $(OBJS_F) $(OBJS_C) -lpsmile.$(CHAN) -lscrip -lmct -lmpeu -o $(ARCHDIR)/lib/liboasis.C.bindings.so


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

cbindings.o: $(SRC_F)/cbindings.F90
	$(F90) $(FFLAGS) -c $(SRC_F)/cbindings.F90

