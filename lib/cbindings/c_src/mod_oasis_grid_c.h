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


#ifndef __MOD_OASIS_GRID_H__
#define __MOD_OASIS_GRID_H__

void oasis_start_grids_writing_iso(int *kinfo);

void oasis_write_grid_iso(const char** cgrid, const int* nx, const int* ny, const int* nx_loc, const int* ny_loc, const double* lon, const double* lat, const int* partid);

void oasis_write_corner_iso(const char** cgrid, const int* nx, const int* ny, const int* nc, const int* nx_loc, const int* ny_loc, const double* clo, const double* cla, const int* partid);

void oasis_write_mask_iso(const char** cgrid, const int* nx, const int* ny, const int* nx_loc, const int* ny_loc, const int* mask, const int* partid, const char** companion);

void oasis_write_frac_iso(const char** cgrid, const int* nx, const int* ny, const int* nx_loc, const int* ny_loc, const double* frac, const int* partid, const char** companion);

void oasis_write_area_iso(const char** cgrid, const int* nx, const int* ny, const int* nx_loc, const int* ny_loc, const double* area, const int* partid);

void oasis_write_angle_iso(const char** cgrid, const int* nx, const int* ny, const int* nx_loc, const int* ny_loc, const double* angle, const int* partid);

void oasis_terminate_grids_writing_iso();


void oasis_c_start_grids_writing(int *kinfo);

void oasis_c_write_grid(const char* cgrid, const int nx, const int ny, const int nx_loc, const int ny_loc, const double* lon, const double* lat, const int partid);

void oasis_c_write_corner(const char* cgrid, const int nx, const int ny, const int nc, const int nx_loc, const int ny_loc, const double* clo, const double* cla, const int partid);

void oasis_c_write_mask(const char* cgrid, const int nx, const int ny, const int nx_loc, const int ny_loc, const int* mask, const int partid, const char* companion);

void oasis_c_write_frac(const char* cgrid, const int nx, const int ny, const int nx_loc, const int ny_loc, const double* frac, const int partid, const char* companion);

void oasis_c_write_area(const char* cgrid, const int nx, const int ny, const int nx_loc, const int ny_loc, const double* area, const int partid);

void oasis_c_write_angle(const char* cgrid, const int nx, const int ny, const int nx_loc, const int ny_loc, const double* angle, const int partid);

void oasis_c_terminate_grids_writing();


#endif
