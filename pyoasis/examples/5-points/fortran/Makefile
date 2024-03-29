include ../../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS) -L$(ARCHDIR)/lib

all: sender-points receiver

sender-points: sender-points.F90
	${F90} sender-points.F90 ${FLAGS} -o sender-points -lpsmile.MPI1 -lscrip -lmct -lmpeu ${FLIBS}

receiver: receiver.F90
	${F90} receiver.F90 ${FLAGS} -o receiver -lpsmile.MPI1 -lscrip -lmct -lmpeu ${FLIBS}

clean:
	rm -f sender-points receiver
