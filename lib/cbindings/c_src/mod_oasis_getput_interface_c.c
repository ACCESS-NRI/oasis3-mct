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


#include "oasis_c.h"
#include "oasis_c_iso.h"

int oasis_c_put(const int var_id, const int kstep, const int size1, const int size2, const int size3, const int fkind, const int storage, const void* fld1, const bool write_restart, int* kinfo){
  if ( fkind == OASIS_Real) {
    oasis_put_iso_float(&var_id, &kstep, &size1, &size2, &size3, (float*)fld1, kinfo, &write_restart);
  } else {
    oasis_put_iso_double(&var_id, &kstep, &size1, &size2, &size3, fld1, kinfo, &write_restart);
  }
  if ( IS_VALID_PUT(*kinfo) ) {
    return OASIS_Ok;
  } else {
    return OASIS_Error;
  }
}

int oasis_c_get(const int var_id, const int kstep, const int size1, const int size2, const int size3, const int fkind, const int storage, void* fld1, int* kinfo){
  if ( fkind == OASIS_Real) {
    oasis_get_iso_float(&var_id, &kstep, &size1, &size2, &size3, (float*)fld1, kinfo);
  } else {
    oasis_get_iso_double(&var_id, &kstep, &size1, &size2, &size3, fld1, kinfo);
  }
  if ( IS_VALID_GET(*kinfo) ) {
    return OASIS_Ok;
  } else {
    return OASIS_Error;
  }
}
