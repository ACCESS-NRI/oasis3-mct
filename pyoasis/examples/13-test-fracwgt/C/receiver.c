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

  int nx_global = 144;
  int ny_global = 143;
  int n_points = nx_global*ny_global;

  int ncid, varid;
  if (nc_open("grids.nc", 0, &ncid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in opening grids.nc",
				    __FILE__, __LINE__));

  double lon[ny_global][nx_global];
  double lat[ny_global][nx_global];
  if (nc_inq_varid(ncid, "bggd.lon", &varid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting bggd.lon id",__FILE__, __LINE__));
  if (nc_get_var(ncid, varid, &lon[0][0]) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting bggd.lon values",__FILE__, __LINE__));
  if (nc_inq_varid(ncid, "bggd.lat", &varid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting bggd.lat id",__FILE__, __LINE__));
  if (nc_get_var(ncid, varid, &lat[0][0]) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting bggd.lat values",__FILE__, __LINE__));
  if (nc_close(ncid))
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in closing grids.nc",__FILE__, __LINE__));

  if (nc_open("masks.nc", 0, &ncid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in opening masks.nc",
				    __FILE__, __LINE__));
  int mask[ny_global][nx_global];
  if (nc_inq_varid(ncid, "bggd.msk", &varid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting bggd.msk id",__FILE__, __LINE__));
  if (nc_get_var(ncid, varid, &mask[0][0]) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in getting bggd.msk values",__FILE__, __LINE__));
  if (nc_close(ncid))
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Receiver: Error in closing grids.nc",__FILE__, __LINE__));

  int part_params[OASIS_Serial_Params];
  part_params[OASIS_Strategy] = OASIS_Serial;
  part_params[OASIS_Length] = n_points;
  int part_id;
  OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, OASIS_Serial_Params,
					part_params, OASIS_No_Gsize,
					OASIS_No_Name));

  char *sca_name  = "FRECVSCA";
  char *frc_name  = "FRECVFRC";
  char *nor_name  = "FRECVNOR";
  int bundle_size = 1;
  int sca_id, frc_id, nor_id;
  OASIS_CHECK_ERR(oasis_c_def_var(&sca_id, sca_name, part_id, bundle_size, OASIS_IN, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_def_var(&frc_id, frc_name, part_id, bundle_size, OASIS_IN, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_def_var(&nor_id, nor_name, part_id, bundle_size, OASIS_IN, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_enddef());

  double scaled[ny_global][nx_global];
  double frac[ny_global][nx_global];
  double normalized[ny_global][nx_global];
  int date = 0;
  int kinfo;
  OASIS_CHECK_ERR(oasis_c_get(sca_id, date, n_points, 1, bundle_size, OASIS_DOUBLE, OASIS_COL_MAJOR, scaled, &kinfo));
  fprintf(stdout, "Receiver: oasis_c_get returned kinfo = %d\n", kinfo);
  fflush(stdout);
  OASIS_CHECK_ERR(oasis_c_get(frc_id, date, n_points, 1, bundle_size, OASIS_DOUBLE, OASIS_COL_MAJOR, frac, &kinfo));
  fprintf(stdout, "Receiver: oasis_c_get returned kinfo = %d\n", kinfo);
  fflush(stdout);
  OASIS_CHECK_ERR(oasis_c_get(nor_id, date, n_points, 1, bundle_size, OASIS_DOUBLE, OASIS_COL_MAJOR, normalized, &kinfo));
  fprintf(stdout, "Receiver: oasis_c_get returned kinfo = %d\n", kinfo);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_terminate());

  double dp_conv = atan(1.)/45.0;
  double epsilon = 1.e-3;

  int i, j;
  double error;
  error = 0.;
  for (i = 0; i<nx_global; i++)
    for (j = 0; j<ny_global; j++)
      if (mask[j][i] == 0 && frac[j][i] > 0.0)
	error += fabs((normalized[j][i] - (scaled[j][i]/frac[j][i]))/normalized[j][i]);

  bool success = error/(double)n_points < epsilon;
  if (success) {
    fprintf(stdout, "Receiver: Data field is ok\n");
    fflush(stdout);
  } else {
    fprintf(stdout, "Receiver: Error is %f\n", error/(double)n_points);
    fflush(stdout);
  }

  if (success) {
      fprintf(stdout, "Receiver: Data received successfully\n");
      fflush(stdout);
  }

}
