#ifndef __MOD_OASIS_GRID_H__
#define __MOD_OASIS_GRID_H__


void oasis_write_grid_iso(char** cgrid, int* nx, int* ny, int* nlon1, int* nlon2, double** lon, int* nlat1, int* nlat2, double** lat, int* partid);

void oasis_write_corner_iso(char** cgrid, int* nx, int* ny, int* nc, int* nclon1, int* nclon2, int* nclon3, double** clon, int* nclat1, int* nclat2, int* nclat3, double** clat, int* partid);

void oasis_write_mask_iso(char** cgrid, int* nx, int* ny, int* nmask1, int* nmask2, int** mask, int* partid);

void oasis_write_area_iso(char** cgrid, int* nx, int* ny, int* narea1, int* narea2, double** area, int* partid);

void oasis_terminate_grids_writing_iso();


void write_grid(char* cgrid, int nx, int ny, int nlon1, int nlon2, double* lon, int nlat1, int nlat2, double* lat, int partid);

void write_corner(char* cgrid, int nx, int ny, int nc, int nclon1, int nclon2, int nclon3, double* clon, int nclat1, int nclat2, int nclat3, double* clat, int partid);

void write_mask(char* cgrid, int nx, int ny, int nmask1, int nmask2, int* mask, int partid);

void write_area(char* cgrid, int nx, int ny, int narea1, int narea2, double* area, int partid);

void terminate_grids_writing();


#endif
