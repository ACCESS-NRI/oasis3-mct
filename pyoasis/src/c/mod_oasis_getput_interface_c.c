#include "mod_oasis_getput_interface_c.h"


void put(int var_id, int kstep, int size1, int size2, int size3, double* field, int *kinfo){
  oasis_put_iso(&var_id, &kstep, &size1, &size2, &size3, field, kinfo);    
}

void get(int var_id, int kstep, int size1, int size2, int size3, double* field, int* kinfo){
  oasis_get_iso(&var_id, &kstep, &size1, &size2, &size3, field, kinfo); 
}
