#include "mod_oasis_part_c.h"
#include <stdio.h>

void def_partition(int* id_part, int* kparal, int* kinfo, int ig_size, char* name){
  oasis_def_partition_iso(id_part, kparal, kinfo, &ig_size, &name);   
}


