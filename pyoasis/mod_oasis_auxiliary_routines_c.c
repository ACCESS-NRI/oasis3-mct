#include "mod_oasis_auxiliary_routines_c.h"


void get_localcomm(int* localcomm, int* kinfo){
  get_localcomm_iso(localcomm, kinfo);
}

void create_couplcomm(int icpl, int allcomm, int* cplcomm, int* error){
  create_couplcomm_iso(&icpl, &allcomm, cplcomm, error);
}

void set_couplcomm(int localcomm, int* kinfo){
  set_couplcomm_iso(&localcomm, kinfo);   
}

void get_intercomm(int new_comm, char* cdnam, int* error){
  get_intercomm_iso(&new_comm, &cdnam, error);   
}

void get_intracomm(int new_comm, char* cdnam, int* error){
  get_intracomm_iso(&new_comm, &cdnam, error);   
}

void set_debug(int debug, int* kinfo){
  oasis_set_debug_iso(&debug, kinfo);   
}

void get_debug(int* debug, int* kinfo){
  oasis_get_debug_iso(debug, kinfo);
}

void put_inquire(int varid, int msec,int* kinfo){
  oasis_put_inquire_iso(&varid, &msec, kinfo);  
}

void get_ncpl(int varid, int* ncpl, int* kinfo){
  oasis_get_ncpl_iso(&varid, ncpl, kinfo);  
}

void get_freqs(int varid, int mop, int ncpl, int* cpl_freqs, int* kinfo){
  oasis_get_freqs_iso(&varid, &mop, &ncpl, &cpl_freqs, kinfo);
}
