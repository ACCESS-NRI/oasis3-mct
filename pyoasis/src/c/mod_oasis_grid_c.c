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


#include "mod_oasis_grid_c.h"

void start_grids_writing(int* kinfo){
  oasis_start_grids_writing_iso(kinfo);
}

void write_grid(char* cgrid, int nx, int ny, int nx_loc, int ny_loc, double* lon, double* lat, int partid){
  oasis_write_grid_iso(&cgrid, &nx, &ny, &nx_loc, &ny_loc, lon, lat, &partid);
}

void write_corner(char* cgrid, int nx, int ny, int nc, int nx_loc, int ny_loc, double* clo, double* cla, int partid){
  oasis_write_corner_iso(&cgrid, &nx, &ny, &nc, &nx_loc, &ny_loc, clo, cla, &partid);   
}

void write_mask(char* cgrid, int nx, int ny, int nx_loc, int ny_loc, int* mask, int partid){
    oasis_write_mask_iso(&cgrid, &nx, &ny, &nx_loc, &ny_loc, mask, &partid);
}

void write_area(char* cgrid, int nx, int ny, int nx_loc, int ny_loc, double* area, int partid){
    oasis_write_area_iso(&cgrid, &nx, &ny, &nx_loc, &ny_loc, area, &partid);
}

void write_frac(char* cgrid, int nx, int ny, int nx_loc, int ny_loc, double* frac, int partid){
    oasis_write_frac_iso(&cgrid, &nx, &ny, &nx_loc, &ny_loc, frac, &partid);
}

void terminate_grids_writing(){
  oasis_terminate_grids_writing_iso();
}
