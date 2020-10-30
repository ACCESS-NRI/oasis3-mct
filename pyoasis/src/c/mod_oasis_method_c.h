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


void init_comp_iso(int* comp_id, const char** comp_name, int* error, const bool* coupled, int* communicator);

void enddef_iso(int* kinfo);

void terminate_iso(int* kinfo);

void get_comm_size_iso(int* communicator, int* comm_size, int* error);

void get_comm_rank_iso(int* communicator, int* comm_rank, int* error);


void init_comp(int* comp_id, const char* comp_name, int* error, const bool coupled, const int communicator);

void enddef(int* kinfo);

void terminate(int* kinfo);

void get_comm_size(int communicator, int* comm_size, int* error);

void get_comm_rank(int communicator, int* comm_rank, int* error);


#ifdef  __cplusplus
}
#endif


#endif
