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


void oasis_c_get_localcomm(int* localcomm, int* kinfo){
  oasis_get_localcomm_iso(localcomm, kinfo);
}

void oasis_c_create_couplcomm(const int icpl, const int allcomm, int* cplcomm, int* kinfo){
  oasis_create_couplcomm_iso(&icpl, &allcomm, cplcomm, kinfo);
}

void oasis_c_set_couplcomm(const int localcomm, int* kinfo){
  oasis_set_couplcomm_iso(&localcomm, kinfo);
}

void oasis_c_get_intercomm(int* new_comm, char* cdnam, int* kinfo){
  oasis_get_intercomm_iso(new_comm, &cdnam, kinfo);
}

void oasis_c_get_intracomm(int* new_comm, char* cdnam, int* kinfo){
  oasis_get_intracomm_iso(new_comm, &cdnam, kinfo);
}

void oasis_c_get_multi_intracomm(int* new_comm, const int cdnam_size, char** cdnam, int* root_ranks, int* kinfo){
  oasis_get_multi_intracomm_iso(new_comm, &cdnam_size, cdnam, root_ranks, kinfo);
}

void oasis_c_set_debug(const int debug, int* kinfo){
  oasis_set_debug_iso(&debug, kinfo);
}

void oasis_c_get_debug(int* debug, int* kinfo){
  oasis_get_debug_iso(debug, kinfo);
}

void oasis_c_put_inquire(const int varid, const int msec, int* kinfo){
  oasis_put_inquire_iso(&varid, &msec, kinfo);
}

void oasis_c_get_ncpl(const int varid, int* ncpl, int* kinfo){
  oasis_get_ncpl_iso(&varid, ncpl, kinfo);
}

void oasis_c_get_freqs(const int varid, const int mop, const int ncpl, int* cpl_freqs, int* kinfo){
  oasis_get_freqs_iso(&varid, &mop, &ncpl, cpl_freqs, kinfo);
}
