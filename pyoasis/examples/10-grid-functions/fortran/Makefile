include ../../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS) -I$(ARCHDIR)/include -I$(NETCDF_INCLUDE) -L$(ARCHDIR)/lib

all: writer

writer: writer.F90
	${F90} writer.F90 ${FLAGS} -o writer -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

clean:
	rm -f writer
