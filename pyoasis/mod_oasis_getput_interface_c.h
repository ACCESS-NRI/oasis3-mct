#ifndef __MOD_OASIS_GETPUT_INTERFACE_C_H__
#define __MOD_OASIS_GETPUT_INTERFACE_C_H__

#include <stdbool.h>


void oasis_put_iso(int* var_id, int* kstep, int* size1, int* size2, int* size3, double* field, int* kinfo);

void oasis_get_iso(int* var_id, int* kstep, int* size1, int* size2, int* size3, double* field, int* kinfo);


void put(int var_id, int kstep, int size1, int size2, int size3, double *field, int *kinfo);

void get(int var_id, int kstep, int size1, int size2, int size3, double* field, int* kinfo);


#endif
