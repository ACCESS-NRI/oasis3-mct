#include "mod_oasis_method_c.h"
#include <stdio.h>


void init_comp(int* comp_id, const char* comp_name, int* error, const bool coupled, int communicator){
    int communicator_f=communicator;
    init_comp_iso(comp_id, &comp_name, error, &coupled, &communicator_f);
}

void enddef(int* kinfo){
  enddef_iso(kinfo);
}

void terminate(int* kinfo){
  terminate_iso(kinfo);
}
