#include <stdio.h>
#include <math.h>
#include "mpi.h"
#include "netcdf.h"
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "sender-cube";
  int comp_id;
  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, OASIS_COUPLED));

  MPI_Comm localcomm;
  OASIS_CHECK_ERR(oasis_c_get_localcomm(&localcomm));
  int comm_size;
  OASIS_CHECK_MPI_ERR(MPI_Comm_size(localcomm, &comm_size));
  int comm_rank;
  OASIS_CHECK_MPI_ERR(MPI_Comm_rank(localcomm, &comm_rank));
  if (comm_rank == 0) {
    fprintf(stdout,"%s: Component ID: %d\n", comp_name, comp_id);
  }

  int nx_global = 362;
  int ny_global = 294;
  int nz_global = 3;
  int n_points = nx_global*ny_global;

  int xdec;
  for (xdec = ceil(sqrt((float)comm_size)); xdec <= comm_size; xdec++) {
    if (comm_size % xdec == 0) break;
  }
  int ydec = comm_size / xdec;

  int ncid, varid;
  if (nc_open("grids.nc", 0, &ncid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in opening grids.nc",
				    __FILE__, __LINE__));

  float lon[ny_global][nx_global];
  float lat[ny_global][nx_global];
  if (nc_inq_varid(ncid, "nogt.lon", &varid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in getting nogt.lon id",__FILE__, __LINE__));
  if (nc_get_var(ncid, varid, &lon[0][0]) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in getting nogt.lon values",__FILE__, __LINE__));
  if (nc_inq_varid(ncid, "nogt.lat", &varid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in getting nogt.lat id",__FILE__, __LINE__));
  if (nc_get_var(ncid, varid, &lat[0][0]) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in getting nogt.lat values",__FILE__, __LINE__));
  if (nc_close(ncid))
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in closing grids.nc",__FILE__, __LINE__));

  int nx = nx_global / xdec;
  int ny = ny_global / ydec;

  int idx = nx * (comm_rank % xdec);
  int idy = ny * floor((float)comm_rank / (float)xdec);

  if ( idx + nx > nx_global ) nx = nx_global - idx;
  if ( idy + ny > ny_global ) ny = ny_global - idx;

  int offset = nx_global * idy + idx;

  int partb_params[OASIS_Box_Params];
  partb_params[OASIS_Strategy] = OASIS_Box;
  partb_params[OASIS_Offset]   = offset;
  partb_params[OASIS_SizeX]    = nx;
  partb_params[OASIS_SizeY]    = ny;
  partb_params[OASIS_LdX]      = nx_global;
  int partb_id;
  OASIS_CHECK_ERR(oasis_c_def_partition(&partb_id, OASIS_Box_Params,
					partb_params, nx_global * ny_global,
					OASIS_No_Name));

  int partc_params[OASIS_Cube_Params];
  partc_params[OASIS_Strategy] = OASIS_Cube;
  partc_params[OASIS_Offset]   = offset;
  partc_params[OASIS_SizeX]    = nx;
  partc_params[OASIS_SizeY]    = ny;
  partc_params[OASIS_LdX]      = nx_global;
  partc_params[OASIS_LdY]      = ny_global;
  partc_params[OASIS_LdZ]      = nz_global;
  int partc_id;
  OASIS_CHECK_ERR(oasis_c_def_partition(&partc_id, OASIS_Cube_Params,
					partc_params, nx_global * ny_global * nz_global,
					OASIS_No_Name));


  char *fl1_name  = "FSENDLV1";
  char *fl2_name  = "FSENDLV2";
  char *fl3_name  = "FSENDLV3";
  char *f3d_name  = "FSENDF3D";
  int bundle_size = 1;
  int fl1_id, fl2_id, fl3_id, f3d_id;
  OASIS_CHECK_ERR(oasis_c_def_var(&fl1_id, fl1_name, partb_id, bundle_size, OASIS_OUT, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_def_var(&fl2_id, fl2_name, partb_id, bundle_size, OASIS_OUT, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_def_var(&fl3_id, fl3_name, partb_id, bundle_size, OASIS_OUT, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_def_var(&f3d_id, f3d_name, partc_id, bundle_size, OASIS_OUT, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_enddef());

  int local_size = (int) n_points / comm_size ;
  if ( comm_rank == comm_size - 1) local_size = n_points - offset;

  double dp_conv = atan(1.)/45.0;
  double field[nz_global][ny][nx];
  int i, j, ll_i, ll_j;
  for (i = 0; i<nx; i++) {
    for (j = 0; j<ny; j++) {
      ll_i = idx + i;
      ll_j = idy + j;
      field[0][j][i] = 2.0 + pow(sin(4.0*lat[ll_j][ll_i]*dp_conv),4.0) *
	cos(8.0 * lon[ll_j][ll_i]*dp_conv);
      field[1][j][i] = 2.0 + pow(sin(2.0*lat[ll_j][ll_i]*dp_conv),4.0) *
	cos(4.0 * lon[ll_j][ll_i]*dp_conv);
      field[2][j][i] = 2.0 - cos(atan(1.)*4.*
			     (acos(cos(lon[ll_j][ll_i]*dp_conv)*cos(lat[ll_j][ll_i]*dp_conv))/
			      (1.2*atan(1.)*4)));
    }
  }
  int date = 0;

  int kinfo;
  OASIS_CHECK_ERR(oasis_c_put(fl1_id, date, nx * ny, 1, bundle_size, OASIS_DOUBLE, OASIS_COL_MAJOR, &field[0][0][0], OASIS_No_Restart, &kinfo));
  fprintf(stdout, "Sender rank(%d): oasis_c_put at time %d returned kinfo = %d\n", comm_rank, date, kinfo);
  fflush(stdout);
  OASIS_CHECK_ERR(oasis_c_put(fl2_id, date, nx * ny, 1, bundle_size, OASIS_DOUBLE, OASIS_COL_MAJOR, &field[1][0][0], OASIS_No_Restart, &kinfo));
  fprintf(stdout, "Sender rank(%d): oasis_c_put at time %d returned kinfo = %d\n", comm_rank, date, kinfo);
  fflush(stdout);
  OASIS_CHECK_ERR(oasis_c_put(fl3_id, date, nx * ny, 1, bundle_size, OASIS_DOUBLE, OASIS_COL_MAJOR, &field[2][0][0], OASIS_No_Restart, &kinfo));
  fprintf(stdout, "Sender rank(%d): oasis_c_put at time %d returned kinfo = %d\n", comm_rank, date, kinfo);
  fflush(stdout);
  OASIS_CHECK_ERR(oasis_c_put(f3d_id, date, nx * ny * nz_global, 1, bundle_size, OASIS_DOUBLE, OASIS_COL_MAJOR, field, OASIS_No_Restart, &kinfo));
  fprintf(stdout, "Sender rank(%d): oasis_c_put at time %d returned kinfo = %d\n", comm_rank, date, kinfo);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_terminate());

}
