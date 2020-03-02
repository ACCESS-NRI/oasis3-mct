#include "mod_oasis_var_c.h"
#include <stdlib.h>
#include <stdio.h>


void def_var(int* id_nports, char* cdport, int id_part, int id_var_nodims1, int id_var_nodims2, int kinout, int n, int* id_var_shape, int ktype, int* kinfo){
  oasis_def_var_iso(id_nports, &cdport, &id_part, &id_var_nodims1, &id_var_nodims2, &kinout, &n, &id_var_shape, &ktype, kinfo);
}
