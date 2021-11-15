#
include header_Makefile
#
##### User configurable options #####
#
# Case of analytical function:
# FANA1 for standard analytical function
# FANA2 for Gulf  stream as analytical function
CPPKEY_FANA=FANA1 # FANA1 FANA2 FANA3
### End User configurable options ###
#
OBJ_M1 =  routine_hdlerr.o routine_model_abort.o read_all_data.o \
          function_ana.o gradient_bicubic.o \
          distance_rad.o write_all_fields.o \
          def_parallel_decomposition.o gradient_conserv.o
#-------------------------------------------------------------------------------
# General rules
#-------------------------------------------------------------------------------
#
default: all
#
all: oasis3_psmile model1
#
# Compile and link libaries
oasis3_psmile:
	(cd $(O3DIR)/util/make_dir ; $(MAKE) oasis3_psmile -f TopMakefileOasis3)
#
#-------------------------------------------------------------------------------
# Rules for executables
#-------------------------------------------------------------------------------
#
model1: $(OBJ_M1) model1.o $(LIBPSMILE) Makefile
	$(LD) $(LDFLAGS) -o $@ $(OBJ_M1) model1.o $(LIBPSMILE) $(FLIBS) $(NETCDF_LIBRARY)
#
#-------------------------------------------------------------------------------
# Rules for compilation
#-------------------------------------------------------------------------------
#
routine_model_abort.o : routine_model_abort.f90
				$(F90) $(F90FLAGS) -c routine_model_abort.f90
routine_hdlerr.o :		routine_hdlerr.f90
				$(F90) $(F90FLAGS) -c routine_hdlerr.f90
read_all_data.o :		read_all_data.F90
				$(F90) $(F90FLAGS) -c read_all_data.F90
def_parallel_decomposition.o :  def_parallel_decomposition.F90
				$(F90) $(F90FLAGS) -c def_parallel_decomposition.F90
write_all_fields.o :		write_all_fields.F90
				$(F90) $(F90FLAGS) -c write_all_fields.F90
function_ana.o :		function_ana.f90
				$(F90) $(F90FLAGS) -c function_ana.f90
gradient_bicubic.o :	        gradient_bicubic.F90
				$(F90) $(F90FLAGS) -D${CPPKEY_FANA} -c gradient_bicubic.F90
distance_rad.o :		distance_rad.f90
				$(F90) $(F90FLAGS) -c distance_rad.f90
gradient_conserv.o :		gradient_conserv.F90
				$(F90) $(F90FLAGS) -D${CPPKEY_FANA}  -c gradient_conserv.F90

model1.o :	model1.F90 Makefile
		$(F90) $(F90FLAGS) -D${CPPKEY_FANA} -c model1.F90
#
#-------------------------------------------------------------------------------
# Utilities
#-------------------------------------------------------------------------------
#
help:
	more Make.help
#
# Clean directory
#
clean:
	-rm -f *.o *.mod *.MOD model1
	-rm -f i.*.F90 *.L
	-rm -f core core.* 
#
# Make sure to recompile everything
#
realclean: clean remove
remove:
	(cd $(O3DIR)/util/make_dir ; $(MAKE) realclean -f TopMakefileOasis3)
