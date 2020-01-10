#ifndef __MOD_OASIS_AUXILIARY_ROUTINES_C_H__
#define __MOD_OASIS_AUXILIARY_ROUTINES_C_H__


#include <mpi.h>


extern void get_localcomm_iso(int* localcomm, int* kinfo);

extern void create_couplcomm_iso(const int* icpl, int* allcomm, int* cplcomm, int* error);

extern void set_couplcomm_iso(int* localcomm, int* kinfo);

extern void get_intercomm_iso(int* new_comm, char** cdnam, int* error);

extern void get_intracomm_iso(int* new_comm, char** cdnam, int* error);

void oasis_set_debug_iso(int* debug, int* kinfo);

void oasis_get_debug_iso(int* debug, int* kinfo);

void oasis_put_inquire_iso(int* varid, int* msec,int* kinfo);

void oasis_get_ncpl_iso(int* varid, int* ncpl, int* kinfo);

void oasis_get_freqs_iso(int* varid, int* mop, int* ncpl, int** cpl_freqs, int* kinfo);
 
 

void get_localcomm(int* localcomm, int* kinfo);

void create_couplcomm(int icpl, int allcomm, int* cplcomm, int* error);

void set_couplcomm(int localcomm, int* kinfo);

void get_intracomm(int new_comm, char* cdnam, int* error);

void set_debug(int debug, int* kinfo);

void get_debug(int* debug, int* kinfo);

void put_inquire(int varid, int msec,int* kinfo);

void get_ncpl(int varid, int* ncpl, int* kinfo);

void get_freqs(int varid, int mop, int ncpl, int* cpl_freqs, int* kinfo);


#endif
