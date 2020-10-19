include ../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS_1) -I$(ARCHDIR)/include -I$(NETCDF_INCLUDE) -L$(ARCHDIR)/lib

all: sender-apple

sender-apple: sender-apple.F90
	${F90} sender-apple.F90 ${FLAGS} -o sender-apple -lpsmile.MPI1 -lscrip -lsparsematrix

clean:
	rm -f sender-apple
