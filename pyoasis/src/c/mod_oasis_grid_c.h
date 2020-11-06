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
      
void oasis_write_grid_iso(char** cgrid, int* nx, int* ny, int* nx_loc, int* ny_loc, double** lon, double** lat, int* partid);

void oasis_write_corner_iso(char** cgrid, int* nx, int* ny, int* nc, int* nx_loc, int* ny_loc, double** clo, double** cla, int* partid);

void oasis_write_mask_iso(char** cgrid, int* nx, int* ny, int* nx_loc, int* ny_loc, int** mask, int* partid);

void oasis_write_frac_iso(char** cgrid, int* nx, int* ny, int* nx_loc, int* ny_loc, double** frac, int* partid);

void oasis_write_area_iso(char** cgrid, int* nx, int* ny, int* nx_loc, int* ny_loc, double** area, int* partid);

void oasis_terminate_grids_writing_iso();


void start_grids_writing(int *kinfo);
      
void write_grid(char* cgrid, int nx, int ny, int nx_loc, int ny_loc, double* lon, double* lat, int partid);

void write_corner(char* cgrid, int nx, int ny, int nc, int nx_loc, int ny_loc, double* clo, double* cla, int partid);

void write_mask(char* cgrid, int nx, int ny, int nx_loc, int ny_loc, int* mask, int partid);

void write_area(char* cgrid, int nx, int ny, int nx_loc, int ny_loc, double* area, int partid);

void write_frac(char* cgrid, int nx, int ny, int nx_loc, int ny_loc, double* frac, int partid);

void terminate_grids_writing();


#endif
