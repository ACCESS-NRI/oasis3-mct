include ../../../../util/make_dir/make.inc
CFLAGS=$(CCFLAGS) -L$(ARCHDIR)/lib

all: sender-cube receiver

sender-cube: sender-cube.c
	${CC} sender-cube.c ${CFLAGS} -o sender-cube -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) $(NETCDF_LIBRARY)

receiver: receiver.c
	${CC} receiver.c ${CFLAGS} -o receiver -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) $(NETCDF_LIBRARY)

clean:
	rm -f sender-cube receiver ferret.jnl
	rm -f *~
	rm -fr work
