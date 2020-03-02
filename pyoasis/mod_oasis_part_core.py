#!/usr/bin/python

from ctypes import *
import ctypes

import numpy

cdll.LoadLibrary("libpyoasiscore.so")
lib=CDLL("libpyoasiscore.so")



lib.def_partition.argtypes=[ctypes.POINTER(ctypes.c_int), ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int)]
def def_partition(parameters):
  print("££££££££££££ "+str(parameters))
  id_part=c_int(0)
  kinfo=c_int(0)
  n=len(parameters)
  p=(ctypes.c_int * n)(*parameters)
  lib.def_partition(id_part, n, p, kinfo)
  return (id_part.value, kinfo.value)

