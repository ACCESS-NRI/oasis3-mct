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


#ifndef __MOD_OASIS_GETPUT_INTERFACE_C_H__
#define __MOD_OASIS_GETPUT_INTERFACE_C_H__

#include <stdbool.h>


#ifdef  __cplusplus
extern "C" {
#endif


void oasis_put_iso_double(const int* var_id, const int* kstep, const int* size1, const int* size2, const int* size3, const double* fld1, int* kinfo, const bool* write_restart);

void oasis_get_iso_double(const int* var_id, const int* kstep, const int* size1, const int* size2, const int* size3, double* fld1, int* kinfo);


void oasis_put_iso_float(const int* var_id, const int* kstep, const int* size1, const int* size2, const int* size3, const float* fld1, int* kinfo, const bool* write_restart);

void oasis_get_iso_float(const int* var_id, const int* kstep, const int* size1, const int* size2, const int* size3, float* fld1, int* kinfo);


int oasis_c_put(const int var_id, const int kstep, const int size1, const int size2, const int size3, const int fkind, const void* fld1, const bool write_restart);

int oasis_c_get(const int var_id, const int kstep, const int size1, const int size2, const int size3, const int fkind, void* fld1);


#ifdef  __cplusplus
}
#endif


#endif
