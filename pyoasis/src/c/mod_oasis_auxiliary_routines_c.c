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


#include "mod_oasis_auxiliary_routines_c.h"


void get_localcomm(int* localcomm, int* kinfo){
  get_localcomm_iso(localcomm, kinfo);
}

void create_couplcomm(int icpl, int allcomm, int* cplcomm, int* error){
  create_couplcomm_iso(&icpl, &allcomm, cplcomm, error);
}

void set_couplcomm(int localcomm, int* kinfo){
  set_couplcomm_iso(&localcomm, kinfo);   
}

void get_intercomm(int new_comm, char* cdnam, int* error){
  get_intercomm_iso(&new_comm, &cdnam, error);   
}

void get_intracomm(int new_comm, char* cdnam, int* error){
  get_intracomm_iso(&new_comm, &cdnam, error);   
}
