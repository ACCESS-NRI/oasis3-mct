include ../../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS) -L$(ARCHDIR)/lib
CFLAGS=$(CCFLAGS) -L$(ARCHDIR)/lib

all: sender-apple receiver-serial sendrecv-orange

sender-apple: sender-apple.F90
	${F90} sender-apple.F90 ${FLAGS} -o sender-apple -lpsmile.MPI1 -lscrip -lmct -lmpeu ${FLIBS}

receiver-serial: receiver-serial.F90
	${F90} receiver-serial.F90 ${FLAGS} -o receiver-serial -lpsmile.MPI1 -lscrip -lmct -lmpeu ${FLIBS}

sendrecv-orange: sendrecv-orange.c
	${CC} sendrecv-orange.c ${CFLAGS} -o sendrecv-orange -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) ${FLIBS}

clean:
	rm -f sender-apple receiver-serial sendrecv-orange
	rm -f *~
	rm -fr work
