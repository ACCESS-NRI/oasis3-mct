#ifndef __MOD_OASIS_VAR_C_HPP__
#define __MOD_OASIS_VAR_C_HPP__


enum params { OASIS_REAL=4, OASIS_OUT=20, OASIS_IN=21};

void oasis_def_var_iso_(int* id_nports, char** cdport, int* id_part, int* id_var_nodims1, int* id_var_nodims2, int* kinout, int* n, int** id_var_shape, int* ktype, int* kinfo);

void def_var(int* id_nports, char* cdport, int id_part, int id_var_nodims1, int id_var_nodims2, int kinout, int n, int* id_var_shape, int ktype, int* kinfo);




#endif
