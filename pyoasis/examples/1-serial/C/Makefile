include ../../../../util/make_dir/make.inc
CFLAGS=$(CCFLAGS) -L$(ARCHDIR)/lib

all: sender-serial receiver

sender-serial: sender-serial.c
	${CC} sender-serial.c ${CFLAGS} -o sender-serial -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) ${FLIBS}

receiver: receiver.c
	${CC} receiver.c ${CFLAGS} -o receiver -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) ${FLIBS}

clean:
	rm -f sender-serial receiver
	rm -f *~
	rm -fr work
