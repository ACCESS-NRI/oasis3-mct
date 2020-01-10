#ifndef __MOD_OASIS_METHOD_C_H__
#define __MOD_OASIS_METHOD_C_H__

#include <stdbool.h>
#include <mpi.h>


extern void init_comp_iso(int* comp_id, const char** comp_name, int* error, const bool* coupled, int* communicator);

extern void enddef_iso(int* kinfo);

extern void terminate_iso(int* kinfo);



void init_comp(int* comp_id, const char* comp_name, int* error, const bool coupled, const int communicator);

void enddef(int* kinfo);

void terminate(int* kinfo);



#endif
