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


#ifndef __MOD_OASIS_SYS_C_H__
#define __MOD_OASIS_SYS_C_H__


#ifdef  __cplusplus
extern "C" {
#endif


void oasis_abort_iso(const int* id_compid, const char** cd_routine, const char** cd_message, const char** file, const int* line, const int* rcode);

int oasis_c_abort(const int id_compid, const char* cd_routine, const char* cd_message, const char* file, const int line);


#ifdef  __cplusplus
}
#endif


#endif
