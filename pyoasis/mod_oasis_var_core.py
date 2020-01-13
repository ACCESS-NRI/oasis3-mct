#!/usr/bin/python

from ctypes import *
import ctypes

import numpy

cdll.LoadLibrary("libpyoasiscore.so")
lib=CDLL("libpyoasiscore.so")



lib.def_var.argtypes=[ctypes.POINTER(ctypes.c_int), c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.c_int, ctypes.POINTER(ctypes.c_int)]
def def_var(id_part, cdport, id_var_nodims1, id_var_nodims2, kinout, n, ktype):
  id_nports=c_int(0)
  id_var_shape=c_int(0)
  kinfo=c_int(0)
  lib.def_var(id_nports, cdport.encode(), id_part, id_var_nodims1, id_var_nodims2, kinout, n, id_var_shape, ktype,  kinfo)
  return (id_nports, id_var_shape, kinfo)
