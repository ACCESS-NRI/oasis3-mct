FC=mpiifort
OPT=${HOME}/INSTALL/PyOasis
FLAGS=-I${HOME}/INSTALL/oasis3-mct/build/lib/psmile.MPI1 -L${OPT}/lib

all: sender-apple

sender-apple: sender-apple.F90
	${FC} sender-apple.F90 ${FLAGS} -o sender-apple -lpsmile.MPI1 -lscrip -lsparsematrix

clean:
	rm -f sender-apple
