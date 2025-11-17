include ../../../../util/make_dir/make.inc
CFLAGS=$(CCFLAGS) -L$(ARCHDIR)/lib

all: sender-apple receiver

sender-apple: sender-apple.c
	${CC} sender-apple.c ${CFLAGS} -o sender-apple -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) ${FLIBS}

receiver: receiver.c
	${CC} receiver.c ${CFLAGS} -o receiver -loasis.cbind -lpsmile.MPI1 -lscrip -lmct -lmpeu $(F2C_LDFLAGS) ${FLIBS}

clean:
	rm -f sender-apple receiver non_oasis
	rm -f *~
	rm -fr work
