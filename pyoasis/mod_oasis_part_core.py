#!/usr/bin/python3

"""OASIS partition data and methods"""

import ctypes
from ctypes import cdll, CDLL, c_int


cdll.LoadLibrary("libpyoasiscore.so")
LIB = CDLL("libpyoasiscore.so")


LIB.def_partition.argtypes = [ctypes.POINTER(ctypes.c_int),
                              ctypes.c_int, ctypes.POINTER(ctypes.c_int),
                              ctypes.POINTER(ctypes.c_int)]


def def_partition(parameters):
    """The OASIS user interface to define partitions"""
    id_part = c_int(0)
    kinfo = c_int(0)
    n_parameters = len(parameters)
    p_parameters = (ctypes.c_int * n_parameters)(*parameters)
    LIB.def_partition(id_part, n_parameters, p_parameters, kinfo)
    return (id_part.value, kinfo.value)
