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


void get_localcomm_iso(int* localcomm, int* kinfo);

void create_couplcomm_iso(const int* icpl, const int* allcomm, int* cplcomm, int* error);

void set_couplcomm_iso(const int* localcomm, int* kinfo);

void get_intercomm_iso(int* new_comm, char** cdnam, int* error);

void get_intracomm_iso(int* new_comm, char** cdnam, int* error);

void set_debug_iso(const int* debug, int* kinfo);

void get_debug_iso(int* debug, int* kinfo);
 
void put_inquire_iso(const int* varid, const int* msec, int* kinfo);

void get_ncpl_iso(const int* varid, int* ncpl, int* kinfo);

void get_freqs_iso(const int* varid, const int* mop, const int* ncpl, int* cpl_freqs, int* kinfo);


void get_localcomm(int* localcomm, int* kinfo);

void create_couplcomm(const int icpl, const int allcomm, int* cplcomm, int* error);

void set_couplcomm(const int localcomm, int* kinfo);

void get_intercomm(int* new_comm, char* cdnam, int* error);

void get_intracomm(int* new_comm, char* cdnam, int* error);

void set_debug(const int debug, int* kinfo);

void get_debug(int* debug, int* kinfo);
 
void put_inquire(int varid, int msec, int* kinfo);

void get_ncpl(const int varid, int* ncpl, int* kinfo);

void get_freqs(const int varid, const int mop, const int ncpl, int* cpl_freqs, int* kinfo);


#ifdef  __cplusplus
}
#endif


#endif
