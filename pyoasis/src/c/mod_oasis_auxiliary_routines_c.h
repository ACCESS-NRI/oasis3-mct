#ifndef __MOD_OASIS_AUXILIARY_ROUTINES_C_H__
#define __MOD_OASIS_AUXILIARY_ROUTINES_C_H__


#include <mpi.h>


extern void get_localcomm_iso(int* localcomm, int* kinfo);

extern void create_couplcomm_iso(const int* icpl, int* allcomm, int* cplcomm, int* error);

extern void set_couplcomm_iso(int* localcomm, int* kinfo);

extern void get_intercomm_iso(int* new_comm, char** cdnam, int* error);

extern void get_intracomm_iso(int* new_comm, char** cdnam, int* error);


void get_localcomm(int* localcomm, int* kinfo);

void create_couplcomm(int icpl, int allcomm, int* cplcomm, int* error);

void set_couplcomm(int localcomm, int* kinfo);

void get_intracomm(int new_comm, char* cdnam, int* error);


#endif
