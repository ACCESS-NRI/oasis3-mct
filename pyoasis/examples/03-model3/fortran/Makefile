OPT=${HOME}/opt

all: model3a model3b

model3a: model3a.F90
	mpif90 model3a.F90 -o model3a -J../../../oasis/modules -L${OPT}/lib -lpsmile.MPI1 -lscrip -lsparsematrix

model3b: model3b.F90
	mpif90 model3b.F90 -o model3b -J../../../oasis/modules -L${OPT}/lib -lpsmile.MPI1 -lscrip -lsparsematrix

clean:
	rm -f model3a model3b 
