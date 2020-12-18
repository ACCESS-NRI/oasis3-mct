#include <stdio.h>
#include "oasis_c.h"

int main(int argc, char *argv[])
{
  char *comp_name = "sender-serial";
  fprintf(stdout,"Component name: %s\n", comp_name);
  fflush(stdout);

  const bool coupled = 1;
  int comp_id;

  OASIS_CHECK_ERR(oasis_c_init_comp(&comp_id, comp_name, coupled));
  fprintf(stdout, "Sender: Component ID: %d\n", comp_id);
  fflush(stdout);

  const int n_points = 1600;
  const int part_params_size = 3;
  int part_params[part_params_size];
  part_params[0] = 0;
  part_params[1] = 0;
  part_params[2] = n_points;
  int part_id;

  OASIS_CHECK_ERR(oasis_c_def_partition(&part_id, part_params_size, part_params, 0, ""));
  fprintf(stdout, "Sender: part_id: %d\n", part_id);
  fflush(stdout);

  char *var_name  = "FSENDOCN";
  fprintf(stdout, "Sender: var_name %s\n", var_name);
  int var_nodims = 1;
  int var_id;

  OASIS_CHECK_ERR(oasis_c_def_var(&var_id, var_name, part_id, var_nodims, OASIS_OUT, OASIS_REAL));
  fprintf(stdout, "Sender: var_id %d\n", var_id);
  fflush(stdout);
  
  OASIS_CHECK_ERR(oasis_c_enddef());

  float field[n_points];
  for (int i = 0; i<n_points; i++) {
    field[i] = (float) i;
  }
  int date = 0;

  int kinfo;
  OASIS_CHECK_ERR(oasis_c_put(var_id, date, n_points, 1, 1, OASIS_REAL, OASIS_COL_MAJOR, field, OASIS_NoRestart, &kinfo));
  fprintf(stdout, "Sender: oasis_c_put returned kinfo = %d\n", kinfo);
  fflush(stdout);
  
  OASIS_CHECK_ERR(oasis_c_terminate());

}
