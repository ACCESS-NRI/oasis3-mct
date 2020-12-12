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


#ifndef __MOD_OASIS_PART_C_HPP__
#define __MOD_OASIS_PART_C_HPP__


#ifdef  __cplusplus
extern "C" {
#endif


extern void oasis_def_partition_iso(int* id_part, const int* kparal_size, const int* kparal, int* kinfo, const int *ig_size, const char** name);

int oasis_c_def_partition(int* id_part, const int kparal_size, const int* kparal, const int ig_size, const char* name);


#ifdef  __cplusplus
}
#endif


#endif
