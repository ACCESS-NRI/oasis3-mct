# Installing YAXT and YAC for OASIS

The use of YAC as a remapping library in OASIS is optional and is triggered by a CPP preprocessing key.  
If it is activated, the OASIS compilation environment has to be adapted and the link step of the final applications has to account for the inclusion of more libraries.

## Prerequisites

YAC is coded in C, with some F90 wrapping interfaces and it relies on the MPI-based YAXT communication library. Both libraries are developed by the DKRZ, therefore their coherency is granted by design.  
YAXT heavily depends on some advanced MPI features and their availability is checked at the `configure` step. Most known MPI distributions are compliant with the requirements. Please notify the OASIS development team if you incurr in a non supported MPI distribution.  
YAC requires a NetCDF installation, but OASIS also does. Let's identify in the following the NetCDF installation root by the `NETCDF4_DIR` enviroment variable.  
Furthermore, YAC uses the lapack and blas optimised linear algebra libraries. They have to be available on your system.  
**N.B.** the compilers and the MPI distribution must be the same used for compiling OASIS and the end user applications.  

## Download the sources

YAXT can be downloaded from the [DKRZ Donwloads page](https://swprojects.dkrz.de/redmine/projects/yaxt/wiki/Downloads)  
Version 0.10.0 has been mirrored on the [CERFACS redmine](https://inle.cerfacs.fr/projects/oasis3-mct/files) 

YAC, as it is needed by OASIS, is not yet officially distributed by the DKRZ.  
For the moment it can be downloaded from the [CERFACS redmine](https://inle.cerfacs.fr/projects/oasis3-mct/files) 

## Setup the compilation environment

### Installation directory (the `prefix`)

Choose the installation directory for the two libraries and make two environment variables point to them, namely  
`YAXT_ROOT`  
`YAC_ROOT`  
Notice that installing the YAXT and YAC libraries in the same directory as OASIS is not recommended for developers, since the `realclean` option of the OASIS makefile, would erase part of the YAXT and YAC installation too. Nevertheless it could be tidier for end users.

These environment variables will be used as `prefix` in the configure step of the installation of the libraries.

### Choice of the compilers

The configure step of both libraries relies on preset environemnt variable for the choice of the compiler and for the optimization flags.  
Please notice that if reproductibility is required independently of the number of MPI processes, a precision preserving optimisation has to be enforced.

#### Intel
```
export CC=mpiicc
export FC=mpiifort
export F90=mpiifort
export CFLAGS='-O2 -fp-model precise'
export FFLAGS='-O2 -fp-model precise'
export FCFLAGS='-O2 -fp-model precise'
```

#### Gnu
```
export CC=mpicc
export FC=mpifort
export F90=mpifort
export CFLAGS='-O2'
export FFLAGS='-O2'
export FCFLAGS='-O2'
```

## YAXT installation

### Configuration

Untar the YAXT sources on your machine (it could also be in the `oasis3-mct/lib` directories with no harm).  
Change directory to the YAXT distribution.
Create a `build` subdirectory and change directory to it.
Issue the following command
```
../configure --prefix=${YAXT_ROOT}
```

### Compilation

From inside the `build` directory, issue the following command (you can tune the number of processes with the ` -j` option)
```
make -j 6 install
```

### Optional checks

The good functioning of YAXT can be optionally checked with the `make check` commands.  
Notice that it is running MPI applications: if the compilation run on a front-end machine with no submission capabilities, the checks will not run.

## YAC installation

### Configuration

Untar the YAC sources on your machine (it could also be in the `oasis3-mct/lib` directories with no harm).  
Change directory to the YAC distribution.
Create a `build` subdirectory and change directory to it.
Issue the following command
```
../configure --enable-lib-core-only --with-yaxt-root=${YAXT_ROOT} --enable-netcdf --with-netcdf-root=${NETCDF4_DIR} --prefix=${YAC_ROOT}
```

### Compilation

From inside the `build` directory, issue the following command (you can tune the number of processes with the ` -j` option)
```
make -j 6 install
```

## Modify the OASIS `make.inc`

When compiling OASIS, the YAC remapping is optional. It has to be activated and the `make.inc` include file has to be adapted.

### Activate the CPP key

Add the `-DYAC_REMAP` key to the `CPPDEF` entry of the `make.inc`

### Provide the YAXT and YAC paths

#### Include path

Define the make variable
```
YAC_INCLUDE = -I$(YAC_ROOT)/include -I$(YAXT_ROOT)/include
```
and add it at the end of the definition of the compilation commands.  
As an example, 
```
F90FLAGS    = $(FCBASEFLAGS) $(INC_DIR) $(CPPDEF) -I$(NETCDF_INCLUDE) $(YAC_INCLUDE)
f90FLAGS    = $(FCBASEFLAGS) $(INC_DIR) $(CPPDEF) -I$(NETCDF_INCLUDE) $(YAC_INCLUDE)
FFLAGS      = $(FCBASEFLAGS) $(INC_DIR) $(CPPDEF) -I$(NETCDF_INCLUDE) $(YAC_INCLUDE)
fFLAGS      = $(FCBASEFLAGS) $(INC_DIR) $(CPPDEF) -I$(NETCDF_INCLUDE) $(YAC_INCLUDE)
CCFLAGS     = $(CCBASEFLAGS) $(INC_DIR) $(CPPDEF) -I$(NETCDF_INCLUDE) $(YAC_INCLUDE)

```

#### Libraries

Define the make variable
```
YAC_LIBRARY = -L $(YAC_ROOT)/lib \
              -L $(YAXT_ROOT)/lib -Wl,-rpath,$(YAXT_ROOT)/lib \
              -lyac_utils -lyac_core -lyaxt_c
```

### Provide access to lapack and blas

#### Intel

With the intel compilers, the lapack and blas are part of the MKL package.  
Simply activate it with `-mkl` or `-qmkl` option (accordingly to the compiler version) of your base compilation command.  
As an example,
```
FCBASEFLAGS := -I. -assume byterecl -mkl
```

#### Gnu

With the gnu compiler, the standard lapack and blas library can be used. There is no need to in indicate the library path with any `-L` option, but the library names have to be explicitly indicated at link time.  
Prepare a make variable for them
```
LAPACK_LIBRARY = -llapack -lblas
```

### Update the `FLIBS` variable for test compilation

The `FLIBS` make variable used in the OASIS tests for the link phase, has to be updated as
```
FLIBS=${YAC_LIBRARY} ${NETCDF_LIBRARY}
```
or for the GNU environments
```
FLIBS=${YAC_LIBRARY} ${NETCDF_LIBRARY} ${LAPACK_LIBRARY}
```
