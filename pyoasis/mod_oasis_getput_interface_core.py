#!/usr/bin/python3

from ctypes import *
import ctypes

import numpy

cdll.LoadLibrary("libpyoasiscore.so")
lib=CDLL("libpyoasiscore.so")

lib.init_comp.argtypes=[ctypes.POINTER(ctypes.c_int), c_char_p, ctypes.POINTER(ctypes.c_int), ctypes.c_bool, ctypes.c_int]




lib.put.argtypes=[ctypes.c_int, ctypes.c_int,  ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_double),  ctypes.POINTER(ctypes.c_int)]
def put(var_id, kstep, sizes, field):
  p_sizes=(ctypes.c_int * len(sizes))(*sizes)    
  error=c_int(0)
  p_field=(ctypes.c_double * len(field))(*field)
  lib.put(var_id, kstep, len(sizes), p_sizes, p_field, error);
  return error.value



lib.get.argtypes=[ctypes.c_int, ctypes.c_int,  ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_double),  ctypes.POINTER(ctypes.c_int)]
def get(var_id, kstep, sizes, field):
  p_sizes=(ctypes.c_int * len(sizes))(*sizes)  
  error=c_int(0)
  p_field=(ctypes.c_double * len(field))(*field)
  lib.get(var_id, kstep, len(sizes), p_sizes, p_field, error);
  return error.value

