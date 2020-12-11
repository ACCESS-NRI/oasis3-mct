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


#ifndef __MOD_OASIS_METHOD_C_H__
#define __MOD_OASIS_METHOD_C_H__

#include <stdbool.h>
#include <mpi.h>


#ifdef  __cplusplus
extern "C" {
#endif


void oasis_init_comp_iso(int* mynummod, const char** cdnam, int* kinfo, const bool* coupled, const int* commworld);

void oasis_enddef_iso(int* kinfo);

void oasis_terminate_iso(int* kinfo);

void oasis_mpi_get_comm_size_iso(const int* communicator, int* comm_size, int* error);

void oasis_mpi_get_comm_rank_iso(const int* communicator, int* comm_rank, int* error);


void oasis_c_init_comp(int* mynummod, const char* cdnam, int* kinfo, const bool coupled, const int commworld);

void oasis_c_enddef(int* kinfo);

void oasis_c_terminate(int* kinfo);

void oasis_c_mpi_get_comm_size(const int communicator, int* comm_size, int* error);

void oasis_c_mpi_get_comm_rank(const int communicator, int* comm_rank, int* error);


#ifdef  __cplusplus
}
#endif


#endif
