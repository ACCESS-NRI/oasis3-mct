include ../../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS) -I$(ARCHDIR)/include -I$(NETCDF_INCLUDE) -L$(ARCHDIR)/lib

all: sender-serial receiver

sender-serial: sender-serial.F90
	${F90} sender-serial.F90 ${FLAGS} -o sender-serial -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

receiver: receiver.F90
	${F90} receiver.F90 ${FLAGS} -o receiver -lpsmile.MPI1 -lscrip -lmct -lmpeu $(NETCDF_LIBRARY)

clean:
	rm -f sender-serial receiver
