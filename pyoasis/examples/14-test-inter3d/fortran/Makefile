include ../../../../util/make_dir/make.inc
FLAGS=$(F90FLAGS) -L$(ARCHDIR)/lib

all: sender-cube receiver

sender-cube: sender-cube.F90
	${F90} sender-cube.F90 ${FLAGS} -o sender-cube -lpsmile.MPI1 -lscrip -lmct -lmpeu ${FLIBS}

receiver: receiver.F90
	${F90} receiver.F90 ${FLAGS} -o receiver -lpsmile.MPI1 -lscrip -lmct -lmpeu ${FLIBS}

clean:
	rm -f sender-cube receiver ferret.jnl
	rm -f *~
	rm -fr work
