#ifndef __MOD_OASIS_METHOD_C_H__
#define __MOD_OASIS_METHOD_C_H__

#include <stdbool.h>
#include <mpi.h>


extern void init_comp_iso(int* comp_id, const char** comp_name, int* error, const bool* coupled, int* communicator);

extern void enddef_iso(int* kinfo);

extern void terminate_iso(int* kinfo);

extern void get_comm_size_iso(int* communicator, int* comm_size, int* error);

extern void get_comm_rank_iso(int* communicator, int* comm_rank, int* error);


void init_comp(int* comp_id, const char* comp_name, int* error, const bool coupled, const int communicator);

void enddef(int* kinfo);

void terminate(int* kinfo);

void get_comm_size(int communicator, int* comm_size, int* error);

void get_comm_rank(int communicator, int* comm_rank, int* error);


#endif
