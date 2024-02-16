#include <stdio.h>
#include <math.h>
#include "mpi.h"
#include "netcdf.h"
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "sender-apple";
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
  int n_points = nx_global*ny_global;

  int ncid, varid;
  if (nc_open("grids.nc", 0, &ncid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in opening grids.nc",
				    __FILE__, __LINE__));

  double lon[n_points];
  double lat[n_points];
  if (nc_inq_varid(ncid, "nogt.lon", &varid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in getting nogt.lon id",__FILE__, __LINE__));
  if (nc_get_var(ncid, varid, lon) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in getting nogt.lon values",__FILE__, __LINE__));
  if (nc_inq_varid(ncid, "nogt.lat", &varid) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in getting nogt.lat id",__FILE__, __LINE__));
  if (nc_get_var(ncid, varid, lat) != NC_NOERR)
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in getting nogt.lat values",__FILE__, __LINE__));
  if (nc_close(ncid))
    OASIS_CHECK_ERR(oasis_c_abort(comp_id, comp_name, "Sender: Error in closing grids.nc",__FILE__, __LINE__));

  int local_size = (int) n_points / comm_size ;
  int offset = comm_rank * local_size;
  if ( comm_rank == comm_size - 1) local_size = n_points - offset;

  int part_params[OASIS_Apple_Params];
  part_params[OASIS_Strategy] = OASIS_Apple;
  part_params[OASIS_Offset] = offset;
  part_params[OASIS_Length] = local_size;
  int part_id;
  OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, OASIS_Apple_Params,
					part_params, OASIS_No_Gsize,
					OASIS_No_Name));

  char *sca_name  = "FSENDSCA";
  char *frc_name  = "FSENDFRC";
  char *nor_name  = "FSENDNOR";
  int bundle_size = 1;
  int sca_id, frc_id, nor_id;
  OASIS_CHECK_ERR(oasis_c_def_var(&sca_id, sca_name, part_id, bundle_size, OASIS_OUT, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_def_var(&frc_id, frc_name, part_id, bundle_size, OASIS_OUT, OASIS_DOUBLE));
  OASIS_CHECK_ERR(oasis_c_def_var(&nor_id, nor_name, part_id, bundle_size, OASIS_OUT, OASIS_DOUBLE));

  OASIS_CHECK_ERR(oasis_c_enddef());

  double dp_conv = atan(1.)/45.0;
  double scaled[local_size];
  double frac[local_size];
  double field[local_size];
  int i;
  for (i = 0; i<local_size; i++) {
    field[i] = 2.0 + pow(sin(lat[offset+i]*dp_conv),3.0) *
      cos(2.0 * lon[offset+i]*dp_conv);
    frac[i] = 1.0 / (1.0 + exp(-0.2*(fabs(lat[offset+i]) -
      60.0 + 10.0 * cos(8.0*lon[offset+i]*dp_conv))));
    if ( frac[i] <= 1.e-1 ) frac[i] = 0.0;
    if ( frac[i] >= 1.0-1.e-1 ) frac[i] = 1.0;
    scaled[i] = field[i] * frac[i];
  }
  int date = 0;

  int kinfo;
  OASIS_CHECK_ERR(oasis_c_put(sca_id, date, local_size, 1, bundle_size, OASIS_DOUBLE, OASIS_ROW_MAJOR, scaled, OASIS_No_Restart, &kinfo));
  fprintf(stdout, "Sender rank(%d): oasis_c_put at time %d returned kinfo = %d\n", comm_rank, date, kinfo);
  fflush(stdout);
  OASIS_CHECK_ERR(oasis_c_put(frc_id, date, local_size, 1, bundle_size, OASIS_DOUBLE, OASIS_ROW_MAJOR, frac, OASIS_No_Restart, &kinfo));
  fprintf(stdout, "Sender rank(%d): oasis_c_put at time %d returned kinfo = %d\n", comm_rank, date, kinfo);
  fflush(stdout);
  OASIS_CHECK_ERR(oasis_c_put_with_frac(nor_id, date, local_size, 1, bundle_size, OASIS_DOUBLE, OASIS_ROW_MAJOR, field, frac, OASIS_No_Restart, &kinfo));
  fprintf(stdout, "Sender rank(%d): oasis_c_put at time %d returned kinfo = %d\n", comm_rank, date, kinfo);
  fflush(stdout);

  OASIS_CHECK_ERR(oasis_c_terminate());

}
