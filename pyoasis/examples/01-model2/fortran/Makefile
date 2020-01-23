OPT=${HOME}/opt

all: model2

model2: model2.F90
	mpif90 model2.F90 -o model2 -J../../../oasis/modules -L${OPT}/lib -lpsmile.MPI1 -lscrip -lsparsematrix

clean:
	rm -f model2
