#ifndef __MOD_OASIS_SYS_C_H__
#define __MOD_OASIS_SYS_C_H__


extern void oasis_abort_iso(const int* comp_id, const char** routine, const char** message, const char** filename, const int* line, const int* error);

void oasis_abort(const int comp_id, const char* routine, const char* message, const char* filename, const int line, const int error);


#endif
