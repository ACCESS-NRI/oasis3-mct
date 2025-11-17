#include <stdio.h>
#include <math.h>
#include "netcdf.h"
#include "mpi.h"
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "receiver";
  fprintf(stdout,"Component name: %s\n", comp_name);
  fflush(stdout);

  int comp_id;
  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, OASIS_COUPLED));
  fprintf(stdout, "Receiver: Component ID: %d\n", comp_id);
  fflush(stdout);

  int nx_global = 182;
  int ny_global = 149;
  int nz_global = 3;
  int n_points_2d = nx_global*ny_global;
  int n_points_3d = n_points_2d*nz_global;

  int ncid, varid;
  if (nc_open("grids.nc", 0, &ncid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in opening grids.nc",
				    __FILE__, __LINE__));

  if (nc_open("masks.nc", 0, &ncid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in opening masks.nc",
				    __FILE__, __LINE__));
  int maskl1[ny_global][nx_global];
  int maskl2[ny_global][nx_global];
  int maskl3[ny_global][nx_global];
  if (nc_inq_varid(ncid, "torc.msk", &varid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting torc.msk id",__FILE__, __LINE__));
  if (nc_get_var(ncid, varid, &maskl1[0][0]) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting torc.msk values",__FILE__, __LINE__));
  if (nc_inq_varid(ncid, "tol2.msk", &varid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting torc.msk id",__FILE__, __LINE__));
  if (nc_get_var(ncid, varid, &maskl2[0][0]) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting torc.msk values",__FILE__, __LINE__));
  if (nc_inq_varid(ncid, "tol3.msk", &varid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting torc.msk id",__FILE__, __LINE__));
  if (nc_get_var(ncid, varid, &maskl3[0][0]) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting torc.msk values",__FILE__, __LINE__));
  if (nc_close(ncid))
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in closing grids.nc",__FILE__, __LINE__));

  int part_params[OASIS_Serial_Params];
  part_params[OASIS_Strategy] = OASIS_Serial;
  part_params[OASIS_Length] = n_points_2d;
  int part2d_id;
  OASIS_CHECK_ERR(oasis_c_def_partition(&part2d_id, OASIS_Serial_Params,
					part_params, OASIS_No_Gsize,
					OASIS_No_Name));

  part_params[OASIS_Length] = n_points_3d;
  int part3d_id;
  OASIS_CHECK_ERR(oasis_c_def_partition(&part3d_id, OASIS_Serial_Params,
					part_params, OASIS_No_Gsize,
					OASIS_No_Name));

  char *fl1_name  = "FRECVLV1";
  char *fl2_name  = "FRECVLV2";
  char *fl3_name  = "FRECVLV3";
  char *f3d_name  = "FRECVF3D";
  int bundle_size = 1;
  int fl1_id, fl2_id, fl3_id, f3d_id;
  OASIS_CHECK_ERR(oasis_c_def_var(&fl1_id, fl1_name, part2d_id, bundle_size, OASIS_IN, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_def_var(&fl2_id, fl2_name, part2d_id, bundle_size, OASIS_IN, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_def_var(&fl3_id, fl3_name, part2d_id, bundle_size, OASIS_IN, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_def_var(&f3d_id, f3d_name, part3d_id, bundle_size, OASIS_IN, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_enddef());

  double fieldl1[ny_global][nx_global];
  double fieldl2[ny_global][nx_global];
  double fieldl3[ny_global][nx_global];
  double field3d[nz_global][ny_global][nx_global];
  int date = 0;
  int kinfo;
  OASIS_CHECK_ERR(oasis_c_get(fl1_id, date, n_points_2d, 1, bundle_size, OASIS_DOUBLE, OASIS_COL_MAJOR, fieldl1, &kinfo));
  fprintf(stdout, "Receiver: oasis_c_get returned kinfo = %d\n", kinfo);
  fflush(stdout);
  OASIS_CHECK_ERR(oasis_c_get(fl2_id, date, n_points_2d, 1, bundle_size, OASIS_DOUBLE, OASIS_COL_MAJOR, fieldl2, &kinfo));
  fprintf(stdout, "Receiver: oasis_c_get returned kinfo = %d\n", kinfo);
  fflush(stdout);
  OASIS_CHECK_ERR(oasis_c_get(fl3_id, date, n_points_2d, 1, bundle_size, OASIS_DOUBLE, OASIS_COL_MAJOR, fieldl3, &kinfo));
  fprintf(stdout, "Receiver: oasis_c_get returned kinfo = %d\n", kinfo);
  fflush(stdout);
  OASIS_CHECK_ERR(oasis_c_get(f3d_id, date, n_points_3d, 1, bundle_size, OASIS_DOUBLE, OASIS_COL_MAJOR, field3d, &kinfo));
  fprintf(stdout, "Receiver: oasis_c_get returned kinfo = %d\n", kinfo);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_terminate());

  double dp_conv = atan(1.)/45.0;
  double epsilon = 1.e-3;

  int i, j;
  double error;
  error = 0.;
  for (i = 0; i<nx_global; i++)
    for (j = 0; j<ny_global; j++) {
      if (maskl1[j][i] == 0) error += fabs(field3d[0][j][i] - fieldl1[j][i])/fieldl1[j][i];
      if (maskl2[j][i] == 0) error += fabs(field3d[1][j][i] - fieldl2[j][i])/fieldl2[j][i];
      if (maskl3[j][i] == 0) error += fabs(field3d[2][j][i] - fieldl3[j][i])/fieldl3[j][i];
    }

  bool success = error/(double)n_points_3d < epsilon;
  if (success) {
    fprintf(stdout, "Receiver: Data field is ok\n");
    fflush(stdout);
  } else {
    fprintf(stdout, "Receiver: Error is %f\n", error/(double)n_points_2d);
    fflush(stdout);
  }

  if (success) {
      fprintf(stdout, "Receiver: Data received successfully\n");
      fflush(stdout);
  }

}
