#include "mod_oasis_part_c.h"
#include <stdio.h>

void def_partition(int* id_part, int n, int* parameters, int* kinfo){
    oasis_def_partition_iso(id_part, &n, parameters, kinfo);   
}
