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


#ifndef __MOD_OASIS_VAR_C_HPP__
#define __MOD_OASIS_VAR_C_HPP__


enum params { OASIS_REAL=4, OASIS_OUT=20, OASIS_IN=21};


#ifdef  __cplusplus
extern "C" {
#endif


void oasis_def_var_iso(int* id_nports, const char** cdport, const int* id_part, const int* id_var_nodims1, const int* id_var_nodims2, const int* kinout, const int* id_var_shape_size, const int** id_var_shape, const int* ktype, int* kinfo);

void oasis_c_def_var(int* id_nports, const char* cdport, const int id_part, const int id_var_nodims1, const int id_var_nodims2, const int kinout, const int id_var_shape_size, const int* id_var_shape, const int ktype, int* kinfo);


#ifdef  __cplusplus
}
#endif


#endif
