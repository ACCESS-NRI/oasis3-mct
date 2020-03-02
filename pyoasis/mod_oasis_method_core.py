#!/usr/bin/python

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

lib.get_comm_size.argtypes=[ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int)]
def get_comm_size(communicator):
  comm_size=c_int(0)
  error=c_int(0)
  lib.get_comm_size(communicator, comm_size, error)
  return comm_size.value

lib.get_comm_rank.argtypes=[ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int)]
def get_comm_rank(communicator):
  comm_rank=c_int(0)
  error=c_int(0)
  lib.get_comm_rank(communicator, comm_rank, error)
  return comm_rank.value
