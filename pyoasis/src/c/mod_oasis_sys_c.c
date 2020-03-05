#include "mod_oasis_sys_c.h"


void oasis_abort(const int comp_id, const char* routine, const char* message, const char* filename, const int line, const int error){
  oasis_abort_iso(&comp_id, &routine, &message, &filename, &line, &error);
}
