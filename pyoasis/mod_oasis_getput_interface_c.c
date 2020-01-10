#include "mod_oasis_getput_interface_c.h"


void put(int var_id, int kstep, int n_dimensions, int* sizes, double* field, int *kinfo){
  oasis_put_iso(&var_id, &kstep, &n_dimensions, &sizes, &field, kinfo);    
}

void get(int var_id, int kstep, int n_dimensions, int* sizes, double* field, int* kinfo){
  oasis_get_iso(&var_id, &kstep, &n_dimensions, &sizes, &field, kinfo);
}
