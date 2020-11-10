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


#include "mod_oasis_var_c.h"
#include <stdlib.h>
#include <stdio.h>


void def_var(int* id_nports, const char* cdport, const int id_part, const int id_var_nodims1, const int id_var_nodims2, const int kinout, const int n, const int* id_var_shape, const int ktype, int* kinfo){
  oasis_def_var_iso(id_nports, &cdport, &id_part, &id_var_nodims1, &id_var_nodims2, &kinout, &n, &id_var_shape, &ktype, kinfo);
}
