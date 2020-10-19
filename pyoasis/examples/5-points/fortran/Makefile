include ../../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS_1) -I$(ARCHDIR)/include -I$(NETCDF_INCLUDE) -L$(ARCHDIR)/lib

all: sender-points receiver

sender-points: sender-points.F90
	${F90} sender-points.F90 ${FLAGS} -o sender-points -lpsmile.MPI1 -lscrip -lsparsematrix

receiver: receiver.F90
	${F90} receiver.F90 ${FLAGS} -o receiver -lpsmile.MPI1 -lscrip -lsparsematrix

clean:
	rm -f sender-points receiver
