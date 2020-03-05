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
