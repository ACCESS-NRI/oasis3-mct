#!/usr/bin/python3

from ctypes import *
import ctypes

import numpy

cdll.LoadLibrary("libpyoasiscore.so")
lib=CDLL("libpyoasiscore.so")



lib.init_comp.argtypes=[ctypes.POINTER(ctypes.c_int), c_char_p, ctypes.POINTER(ctypes.c_int), ctypes.c_bool, ctypes.c_int]
def init_comp(comp_name, coupled, communicator):
  comp_id=c_int(0)
  error=c_int(0)
  lib.init_comp(comp_id, comp_name.encode(), error, coupled, communicator.py2f());
  return (comp_id.value, error.value)

lib.enddef.argtypes=[ctypes.POINTER(ctypes.c_int)]
def enddef():
  error=c_int(0)
  lib.enddef(error)
  return error.value

lib.terminate.argtypes=[ctypes.POINTER(ctypes.c_int)]
def terminate():
  error=c_int(0)
  lib.terminate(error)
  return error.value


