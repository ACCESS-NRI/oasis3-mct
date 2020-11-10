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


void init_comp(int* comp_id, const char* comp_name, int* error, const bool coupled, int communicator){
    int communicator_f=communicator;
    init_comp_iso(comp_id, &comp_name, error, &coupled, &communicator_f);
}

void enddef(int* kinfo){
  enddef_iso(kinfo);
}

void terminate(int* kinfo){
  terminate_iso(kinfo);
}

void get_comm_size(const int communicator, int* comm_size, int* error){
  get_comm_size_iso(&communicator, comm_size, error);  
}

void get_comm_rank(const int communicator, int* comm_rank, int* error){
  get_comm_rank_iso(&communicator, comm_rank, error);  
}
