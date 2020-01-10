#include "mod_oasis_var_c.h"
#include <stdlib.h>

void def_var(int* id_nports, char* cdport, int id_part, int id_var_nodims1, int id_var_nodims2, int kinout, int n, int* id_var_shape, int ktype, int* kinfo){
  int* id_var_nodims=malloc(2*sizeof(int));
  id_var_nodims[0]=id_var_nodims1;
  id_var_nodims[1]=id_var_nodims2;
  oasis_def_var_iso_(id_nports, cdport, &id_part, &id_var_nodims, &kinout, &n, &id_var_shape, &ktype, kinfo);
  free(id_var_nodims);
}
