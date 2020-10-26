#
include header_Makefile
LIBPSMILE = $(ARCHDIR)/lib/libpsmile.${CHAN}.a $(ARCHDIR)/lib/libmct.a $(ARCHDIR)/lib/libmpeu.a $(ARCHDIR)/lib/libscrip.a
#
##### User configurable options #####
DECOMP_M2=DECOMP_APPLE
CPPLOCAL_M2 = -D${DECOMP_M2}
### End User configurable options ###
#
OBJ_M2 =  routine_model_abort.o routine_hdlerr.o read_all_data.o  \
          def_parallel_decomposition_m2.o flddiag.o
#-------------------------------------------------------------------------------
# General rules
#-------------------------------------------------------------------------------
#
default: all
#
all: oasis3_psmile model2
#
# Compile and link libaries
oasis3_psmile:
	(cd $(O3DIR)/util/make_dir ; $(MAKE) oasis3_psmile -f TopMakefileOasis3)
#
#
#-------------------------------------------------------------------------------
# Rules for executables
#-------------------------------------------------------------------------------
#
model2: $(OBJ_M2) model2.o $(LIBPSMILE) Makefile
	$(LD) $(LDFLAGS) -o $@ $(OBJ_M2) model2.o $(LIBPSMILE) $(FLIBS)
#
#-------------------------------------------------------------------------------
# Rules for compilation
#-------------------------------------------------------------------------------
#
routine_model_abort.o :	routine_model_abort.f90
				$(F90) $(F90FLAGS) -c routine_model_abort.f90
routine_hdlerr.o :		routine_hdlerr.f90
				$(F90) $(F90FLAGS) -c routine_hdlerr.f90
read_all_data.o  :		read_all_data.F90
				$(F90) $(F90FLAGS) -c read_all_data.F90
def_parallel_decomposition.o : def_parallel_decomposition.F90
				$(F90) $(F90FLAGS) $(CPPLOCAL_M1) -c def_parallel_decomposition.F90
def_parallel_decomposition_m2.o : 	def_parallel_decomposition.F90
				$(F90) $(F90FLAGS) $(CPPLOCAL_M2) -o def_parallel_decomposition_m2.o -c def_parallel_decomposition.F90
flddiag.o :				flddiag.F90
				$(F90) $(F90FLAGS) -c flddiag.F90

model2.o :	model2.F90 Makefile
		$(F90) $(F90FLAGS) $(CPPLOCAL_M2) -c model2.F90
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
	-rm -f *.o *.mod *.MOD model1 model2
	-rm -f i.*.F90 *.L
	-rm -f core core.* 
#
# Make sure to recompile everything
#
realclean: clean remove
remove:
	(cd $(O3DIR)/util/make_dir ; $(MAKE) realclean -f TopMakefileOasis3)
