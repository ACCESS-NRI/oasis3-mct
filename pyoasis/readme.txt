Makefile
========
It was necessary to add the flag -ffree-line-length-512 in order to compile the Oasis source code. This is done in make.stfc used by make.inc

The makefile also contains a hack that modifies the source code in order to solve issues involving underscores. It also creates shared libraries compiled with the -fPIC flag. This is a temporary solution till the required changes are introduced in Oasis.


pyoasis.F90
===========
Contains functions to convert character strings between C and Fortran


_iso.F90 files
==============
Wrappers in Fortran using ISO C bindings of the corresponding .F90 files in Oasis


_c.h, _c.c files
================
Wrappers in C of the corresponding files


_core.py
========
Wrapper in Python of the corresponding files. This is a basic wrapper using c types.


pyoasis.py
==========
Object-oriented Oasis wrapper concisting of classes and throwing exceptions


