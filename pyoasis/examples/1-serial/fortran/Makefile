FC=mpiifort
OPT=${HOME}/INSTALL/PyOasis
FLAGS=-I${HOME}/INSTALL/oasis3-mct/build/lib/psmile.MPI1 -L${OPT}/lib

all: sender-serial receiver

sender-serial: sender-serial.F90
	${FC} sender-serial.F90 ${FLAGS} -o sender-serial -lpsmile.MPI1 -lscrip -lsparsematrix

receiver: receiver.F90
	${FC} receiver.F90 ${FLAGS} -o receiver -lpsmile.MPI1 -lscrip -lsparsematrix

clean:
	rm -f sender-serial receiver
