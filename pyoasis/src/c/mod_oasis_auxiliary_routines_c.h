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


extern void get_localcomm_iso(int* localcomm, int* kinfo);

extern void create_couplcomm_iso(const int* icpl, int* allcomm, int* cplcomm, int* error);

extern void set_couplcomm_iso(int* localcomm, int* kinfo);

extern void get_intercomm_iso(int* new_comm, char** cdnam, int* error);

extern void get_intracomm_iso(int* new_comm, char** cdnam, int* error);

extern void oasis_set_debug_iso(int* debug, int* kinfo);

extern void oasis_get_debug_iso(int* debug, int* kinfo);
 
extern void oasis_put_inquire_iso(int* varid, int* msec, int* kinfo);

extern void oasis_get_ncpl_iso(int* varid, int* ncpl, int* kinfo);

extern void oasis_get_freqs_iso(int* varid, int* mop, int* ncpl, int* cpl_freqs, int* kinfo);


void get_localcomm(int* localcomm, int* kinfo);

void create_couplcomm(int icpl, int allcomm, int* cplcomm, int* error);

void set_couplcomm(int localcomm, int* kinfo);

void get_intracomm(int new_comm, char* cdnam, int* error);

void oasis_set_debug(int debug, int* kinfo);

void oasis_get_debug(int* debug, int* kinfo);
 
void oasis_put_inquire(int varid, int msec, int* kinfo);

void oasis_get_ncpl(int varid, int* ncpl, int* kinfo);

void oasis_get_freqs(int varid, int mop, int ncpl, int* cpl_freqs, int* kinfo);


#endif
