#!/usr/bin/python3

from ctypes import *
import ctypes

import numpy

cdll.LoadLibrary("libpyoasiscore.so")
lib = CDLL("libpyoasiscore.so")


lib.get_localcomm.argtypes = [ctypes.POINTER(ctypes.c_int),
                              ctypes.POINTER(ctypes.c_int)]


def get_localcomm():
    localcomm = c_int(0)
    error = c_int(0)
    lib.get_localcomm(localcomm, error)
    return (localcomm.value, error.value)

lib.create_couplcomm.argtypes = [ctypes.c_int, ctypes.c_int,
                                 ctypes.POINTER(ctypes.c_int),
                                 ctypes.POINTER(ctypes.c_int)]


def create_couplcomm(icpl, allcomm):
    cplcomm = c_int(0)
    error = c_int(0)
    lib.create_couplcomm(icpl, allcomm, cplcomm, error)
    return (cplcomm.value, error.value)


lib.set_couplcomm.argtypes = [ctypes.c_int,
                              ctypes.POINTER(ctypes.c_int)]


def set_couplcomm(localcomm):
    error = c_int(0)
    lib.set_couplcomm(localcomm, error)
    return error.value


lib.get_intercomm.argtypes = [ctypes.c_int, c_char_p,
                              ctypes.POINTER(ctypes.c_int)]


def get_intercomm(new_comm, cdnam):
    error = c_int(0)
    lib.get_intercomm(new_comm, cdnam.encode(), error)
    return error.value


lib.get_intracomm.argtypes = [ctypes.c_int, c_char_p,
                              ctypes.POINTER(ctypes.c_int)]


def get_intracomm(new_comm, cdnam):
    error = c_int(0)
    lib.get_intracomm(new_comm, cdnam.encode(), error)
    return error.value
