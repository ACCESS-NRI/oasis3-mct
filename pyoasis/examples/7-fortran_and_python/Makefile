FC=mpif90
OPT=${HOME}/opt
FLAGS=-J${HOME}/compile_oa3-mct/build/lib/psmile.MPI1 -L${OPT}/lib

all: sender-apple

sender-apple: sender-apple.F90
	${FC} sender-apple.F90 ${FLAGS} -o sender-apple -lpsmile.MPI1 -lscrip -lsparsematrix

clean:
	rm -f sender-apple
