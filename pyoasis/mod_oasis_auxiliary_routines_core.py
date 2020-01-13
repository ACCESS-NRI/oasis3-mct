#!/usr/bin/python

from ctypes import *
import ctypes

import numpy

cdll.LoadLibrary("libpyoasiscore.so")
lib=CDLL("libpyoasiscore.so")



lib.get_localcomm.argtypes=[ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int)]
def get_localcomm():
  localcomm=c_int(0)
  error=c_int(0)
  lib.get_localcomm(localcomm, error)
  return (localcomm.value, error.value)

lib.create_couplcomm.argtypes=[ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int)]
def create_couplcomm(icpl, allcomm):
  cplcomm=c_int(0)
  error=c_int(0)
  lib.create_couplcomm(icpl, allcomm, cplcomm, error)
  return (cplcomm.value, error.value)

lib.set_couplcomm.argtypes=[ctypes.c_int, ctypes.POINTER(ctypes.c_int)]
def set_couplcomm(localcomm):
  error=c_int(0)
  lib.set_couplcomm(localcomm, error)
  return error.value

lib.get_intercomm.argtypes=[ctypes.c_int, c_char_p, ctypes.POINTER(ctypes.c_int)]
def get_intercomm(new_comm, cdnam):
  error=c_int(0)
  lib.get_intercomm(new_comm, cdnam.encode(), error)
  return error.value

lib.get_intracomm.argtypes=[ctypes.c_int, c_char_p, ctypes.POINTER(ctypes.c_int)]
def get_intracomm(new_comm, cdnam):
  error=c_int(0)
  lib.get_intracomm(new_comm, cdnam.encode(), error)
  return error.value

lib.set_debug.argtypes=[ctypes.c_int]
def set_debug(debug):
    kinfo=c_int(0)
    lib.set_debug(debug, kinfo)
    return kinfo.value

def get_debug():
    debug=c_int(0)
    kinfo=c_int(0)
    lib.get_debug(debug, kinfo)
    return (debug.value, kinfo.value)

lib.put_inquire.argtypes=[ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_int)]
def put_inquire(varid, msec):
    kinfo=c_int(0)
    lib.put_inquire(varid, msec, kinfo)
    return kinfo.value

lib.get_ncpl.argtypes=[ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int)]
def get_ncpl(varid):
    ncpl=c_int(0)
    kinfo=c_int(0)
    get_ncpl(varid, ncpl, kinfo)
    return (ncpl.value, kinfo.value)


lib.get_freqs.argtypes=[ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int)]
def get_freqs(varid, mop, ncpl, cpl_freqs):
  p_cpl_freqs=(ctypes.c_int * len(cpl_freqs))(*cpl_freqs)
  error=c_int(0)
  lib.get_freqs(varid, mop, ncpl, p_cpl_freqs, error)
  return error.value
