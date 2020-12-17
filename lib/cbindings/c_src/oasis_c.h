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


#ifndef __OASIS_C_ROUTINES_C_H__
#define __OASIS_C_ROUTINES_C_H__


#include <stdbool.h>
#include <mpi.h>


#if defined(c_plusplus) || defined(__cplusplus)
extern "C" {
#endif


enum params
{
  OASIS_Real        = 4,
  OASIS_Double      = 8,
  OASIS_Ok          = 0,
  OASIS_NotDef      = -2,
  OASIS_Var_Uncpl   = -1,
  OASIS_Out         = 20,
  OASIS_In          = 21,
  OASIS_InOut       = 2,
  OASIS_Recvd       = 3,
  OASIS_Sent        = 4,
  OASIS_LocTrans    = 5,
  OASIS_ToRest      = 6,
  OASIS_Output      = 7,
  OASIS_SentOut     = 8,
  OASIS_ToRestOut   = 9,
  OASIS_FromRest    = 10,
  OASIS_Input       = 11,
  OASIS_RecvOut     = 12,
  OASIS_FromRestOut = 13,
  OASIS_Waitgroup   = 14,
  OASIS_NONE        = 100,
  OASIS_COMM_READY  = 101,
  OASIS_COMM_WAIT   = 102,
  OASIS_PUT         = 103,
  OASIS_GET         = 104,
  CLIM_Strategy     = 1,
  CLIM_Segments     = 2,
  CLIM_Serial       = 0,
  CLIM_Apple        = 1,
  CLIM_Box          = 2,
  CLIM_Orange       = 3,
  CLIM_Points       = 4,
  CLIM_Offset       = 2,
  CLIM_Length       = 3,
  CLIM_SizeX        = 3,
  CLIM_SizeY        = 4,
  CLIM_LdX          = 5
};

// C interfaces with MPI Communicator defined as C MPI_Comm (for C)

int oasis_c_get_localcomm(MPI_Comm* localcomm);

int oasis_c_create_couplcomm(const int icpl, const MPI_Comm allcomm, MPI_Comm* cplcomm);

int oasis_c_set_couplcomm(const MPI_Comm localcomm);

int oasis_c_get_intercomm(MPI_Comm* new_comm, char* cdnam);

int oasis_c_get_intracomm(MPI_Comm* new_comm, char* cdnam);

int oasis_c_get_multi_intracomm(MPI_Comm* new_comm, const int cdnam_size, char** cdnam, int* root_ranks);

int oasis_c_set_debug(const int debug);

int oasis_c_get_debug(int* debug);

int oasis_c_put_inquire(int varid, int msec);

int oasis_c_get_ncpl(const int varid, int* ncpl);

int oasis_c_get_freqs(const int varid, const int mop, const int ncpl, int* cpl_freqs);

int oasis_c_put(const int var_id, const int kstep, const int size1, const int size2, const int size3, const int fkind, const void* fld1, const bool write_restart);

int oasis_c_get(const int var_id, const int kstep, const int size1, const int size2, const int size3, const int fkind, void* fld1);

int oasis_c_start_grids_writing();

int oasis_c_write_grid(const char* cgrid, const int nx, const int ny, const int nx_loc, const int ny_loc, const double* lon, const double* lat, const int partid);

int oasis_c_write_corner(const char* cgrid, const int nx, const int ny, const int nc, const int nx_loc, const int ny_loc, const double* clo, const double* cla, const int partid);

int oasis_c_write_mask(const char* cgrid, const int nx, const int ny, const int nx_loc, const int ny_loc, const int* mask, const int partid, const char* companion);

int oasis_c_write_frac(const char* cgrid, const int nx, const int ny, const int nx_loc, const int ny_loc, const double* frac, const int partid, const char* companion);

int oasis_c_write_area(const char* cgrid, const int nx, const int ny, const int nx_loc, const int ny_loc, const double* area, const int partid);

int oasis_c_write_angle(const char* cgrid, const int nx, const int ny, const int nx_loc, const int ny_loc, const double* angle, const int partid);

int oasis_c_terminate_grids_writing();

int oasis_c_init_comp_with_comm(int* mynummod, const char* cdnam, const bool coupled, const MPI_Comm commworld);

int oasis_c_init_comp(int* mynummod, const char* cdnam, const bool coupled);

int oasis_c_enddef();

int oasis_c_terminate();

int oasis_c_def_partition(int* id_part, const int kparal_size, const int* kparal, const int ig_size, const char* name);

int oasis_c_abort(const int id_compid, const char* cd_routine, const char* cd_message, const char* file, const int line);

int oasis_c_def_var(int* id_nports, const char* cdport, const int id_part, const int id_var_nodims1, const int id_var_nodims2, const int kinout, const int id_var_shape_size, const int* id_var_shape, const int ktype);


#if defined(c_plusplus) || defined(__cplusplus)
}
#endif


#endif
