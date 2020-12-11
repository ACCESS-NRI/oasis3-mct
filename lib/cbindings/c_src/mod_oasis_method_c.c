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


#include "mod_oasis_method_c.h"
#include <stdio.h>


void oasis_c_init_comp(int* comp_id, const char* comp_name, int* error, const bool coupled, int communicator){
    int communicator_f=communicator;
    oasis_init_comp_iso(comp_id, &comp_name, error, &coupled, &communicator_f);
}

void oasis_c_enddef(int* kinfo){
  oasis_enddef_iso(kinfo);
}

void oasis_c_terminate(int* kinfo){
  oasis_terminate_iso(kinfo);
}

void oasis_c_mpi_get_comm_size(const int communicator, int* comm_size, int* error){
  oasis_mpi_get_comm_size_iso(&communicator, comm_size, error);
}

void oasis_c_mpi_get_comm_rank(const int communicator, int* comm_rank, int* error){
  oasis_mpi_get_comm_rank_iso(&communicator, comm_rank, error);
}
