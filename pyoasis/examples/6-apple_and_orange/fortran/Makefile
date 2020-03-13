FC=mpif90
OPT=${HOME}/opt
FLAGS=-J${HOME}/compile_oa3-mct/build/lib/psmile.MPI1 -L${OPT}/lib

all: sender-apple receiver-orange

sender-apple: sender-apple.F90
	${FC} sender-apple.F90 ${FLAGS} -o sender-apple -lpsmile.MPI1 -lscrip -lsparsematrix

receiver-orange: receiver-orange.F90
	${FC} receiver-orange.F90 ${FLAGS} -o receiver-orange -lpsmile.MPI1 -lscrip -lsparsematrix

clean:
	rm -f sender-apple receiver-orange
