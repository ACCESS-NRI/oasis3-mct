FC=mpif90
OPT=${HOME}/opt
FLAGS=-J${HOME}/compile_oa3-mct/build/lib/psmile.MPI1 -L${OPT}/lib

all: sender-orange receiver

sender-orange: sender-orange.F90
	${FC} sender-orange.F90 ${FLAGS} -o sender-orange -lpsmile.MPI1 -lscrip -lsparsematrix

receiver: receiver.F90
	${FC} receiver.F90 ${FLAGS} -o receiver -lpsmile.MPI1 -lscrip -lsparsematrix

clean:
	rm -f sender-orange receiver
