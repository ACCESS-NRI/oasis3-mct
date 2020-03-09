FC=mpif90
OPT=${HOME}/opt
FLAGS=-J${HOME}/compile_oa3-mct/build/lib/psmile.MPI1 -L${OPT}/lib

all: sender-box receiver

sender-box: sender-box.F90
	${FC} sender-box.F90 ${FLAGS} -o sender-box -lpsmile.MPI1 -lscrip -lsparsematrix

receiver: receiver.F90
	${FC} receiver.F90 ${FLAGS} -o receiver -lpsmile.MPI1 -lscrip -lsparsematrix

clean:
	rm -f sender-box receiver
