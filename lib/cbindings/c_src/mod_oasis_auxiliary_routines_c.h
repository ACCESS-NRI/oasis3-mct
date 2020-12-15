// pyOASIS - A Python wrapper for OASIS
// Authors: Philippe Gambron, Rupert Ford
// Copyright (C) 2019 UKRI - STFC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.

// A copy of the GNU Lesser General Public License, version 3, is supplied
// with this program, in the file lgpl-3.0.txt. It is also available at
// <https://www.gnu.org/licenses/lgpl-3.0.html>.


#ifndef __MOD_OASIS_AUXILIARY_ROUTINES_C_H__
#define __MOD_OASIS_AUXILIARY_ROUTINES_C_H__


#include <mpi.h>


#ifdef  __cplusplus
extern "C" {
#endif

// FORTRAN interfaces

void oasis_get_localcomm_iso(int* localcomm, int* kinfo);

void oasis_create_couplcomm_iso(const int* icpl, const int* allcomm, int* cplcomm, int* kinfo);

void oasis_set_couplcomm_iso(const int* localcomm, int* kinfo);

void oasis_get_intercomm_iso(int* new_comm, char** cdnam, int* kinfo);

void oasis_get_intracomm_iso(int* new_comm, char** cdnam, int* kinfo);

void oasis_get_multi_intracomm_iso(int* new_comm, const int* cdnam_size, char** cdnam, int* root_ranks, int* kinfo);

void oasis_set_debug_iso(const int* debug, int* kinfo);

void oasis_get_debug_iso(int* debug, int* kinfo);

void oasis_put_inquire_iso(const int* varid, const int* msec, int* kinfo);

void oasis_get_ncpl_iso(const int* varid, int* ncpl, int* kinfo);

void oasis_get_freqs_iso(const int* varid, const int* mop, const int* ncpl, int* cpl_freqs, int* kinfo);



// C interfaces with MPI Communicator defined as int (for python)

int oasis_c_get_localcomm_iso2c(int* localcomm);

int oasis_c_create_couplcomm_iso2c(const int icpl, const int allcomm, int* cplcomm);

int oasis_c_set_couplcomm_iso2c(const int localcomm);

int oasis_c_get_intercomm_iso2c(int* new_comm, char* cdnam);

int oasis_c_get_intracomm_iso2c(int* new_comm, char* cdnam);

int oasis_c_get_multi_intracomm_iso2c(int* new_comm, const int cdnam_size, char** cdnam, int* root_ranks);



// C interfaces with MPI Communicator defined as C MPI_Comm (for C)

int oasis_c_get_localcomm(MPI_Comm* localcomm);

int oasis_c_create_couplcomm(const int icpl, const MPI_Comm allcomm, MPI_Comm* cplcomm);

int oasis_c_set_couplcomm(const MPI_Comm localcomm);

int oasis_c_get_intercomm(MPI_Comm* new_comm, char* cdnam);

int oasis_c_get_intracomm(MPI_Comm* new_comm, char* cdnam);

int oasis_c_get_multi_intracomm(MPI_Comm* new_comm, const int cdnam_size, char** cdnam, int* root_ranks);

int oasis_c_set_debug(const int debug);

int oasis_c_get_debug(int* debug);

int oasis_c_put_inquire(int varid, int msec);

int oasis_c_get_ncpl(const int varid, int* ncpl);

int oasis_c_get_freqs(const int varid, const int mop, const int ncpl, int* cpl_freqs);


#ifdef  __cplusplus
}
#endif


#endif
