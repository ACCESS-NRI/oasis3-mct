include ../../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS) -L$(ARCHDIR)/lib

all: sender-apple receiver-orange

sender-apple: sender-apple.F90
	${F90} sender-apple.F90 ${FLAGS} -o sender-apple -lpsmile.MPI1 -lscrip -lmct -lmpeu ${FLIBS}

receiver-orange: receiver-orange.F90
	${F90} receiver-orange.F90 ${FLAGS} -o receiver-orange -lpsmile.MPI1 -lscrip -lmct -lmpeu ${FLIBS}

clean:
	rm -f sender-apple receiver-orange
