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


#include "mod_oasis_getput_interface_c.h"
#include<stdio.h>

void put(int var_id, int kstep, int size1, int size2, int size3, int kind, void* field, int *kinfo){
  if ( kind == 4) {
    oasis_put_iso_float(&var_id, &kstep, &size1, &size2, &size3, (float*)field, kinfo);
  } else {
    oasis_put_iso_double(&var_id, &kstep, &size1, &size2, &size3, field, kinfo);
  }
}

void get(int var_id, int kstep, int size1, int size2, int size3, int kind, void* field, int* kinfo){
  if ( kind == 4) {
    oasis_get_iso_float(&var_id, &kstep, &size1, &size2, &size3, (float*)field, kinfo);
  } else {
    oasis_get_iso_double(&var_id, &kstep, &size1, &size2, &size3, field, kinfo);
  }
}
