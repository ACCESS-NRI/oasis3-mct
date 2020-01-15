OPT=${HOME}/opt

all: model1

model1: model1.F90
	mpif90 model1.F90 -o model1 -J../../../oasis/modules -L${OPT}/lib -lpsmile.MPI1 -lscrip -lsparsematrix

clean:
	rm -f model1
