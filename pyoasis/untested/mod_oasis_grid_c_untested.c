#include "mod_oasis_grid_c.h"


void write_grid(char* cgrid, int nx, int ny, int nlon1, int nlon2, double* lon, int nlat1, int nlat2, double* lat, int partid){
  oasis_write_grid_iso(&cgrid, &nx, &ny, &nlon1, &nlon2, &lon, &nlat1, &nlat2, &lat, &partid);
}

void write_corner(char* cgrid, int nx, int ny, int nc, int nclon1, int nclon2, int nclon3, double* clon, int nclat1, int nclat2, int nclat3, double* clat, int partid){
  oasis_write_corner_iso(&cgrid, &nx, &ny, &nc, &nclon1, &nclon2, &nclon3, &clon, &nclat1, &nclat2, &nclat3, &clat, &partid);   
}

void write_mask(char* cgrid, int nx, int ny, int nmask1, int nmask2, int* mask, int partid){
    oasis_write_mask_iso(&cgrid, &nx, &ny, &nmask1, &nmask2, &mask, &partid);
}

void write_area(char* cgrid, int nx, int ny, int narea1, int narea2, double* area, int partid){
    oasis_write_area_iso(&cgrid, &nx, &ny, &narea1, &narea2, &area, &partid);
}

void terminate_grids_writing(){
  oasis_terminate_grids_writing_iso();
}
