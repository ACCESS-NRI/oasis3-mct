#!/usr/bin/python

from ctypes import *
import ctypes

import numpy

cdll.LoadLibrary("libpyoasiscore.so")
lib=CDLL("libpyoasiscore.so")


lib.def_partition.argtypes=[ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int), ctypes.c_int, c_char_p]
def def_partition(ig_size, name):
  id_part=c_int(0)
  kparal=c_int(0)
  kinfo=c_int(0)
  lib.def_partition(id_part, kparal, kinfo, ig_size, name);
  return (id_part.value, kparal.value, kinfo.value)

