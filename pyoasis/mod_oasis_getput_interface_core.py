#!/usr/bin/python3

from ctypes import *
import ctypes

import numpy

cdll.LoadLibrary("libpyoasiscore.so")
lib = CDLL("libpyoasiscore.so")


def get_sizes(field):
    sizes = list(field.shape)
    n = 3 - len(sizes)
    for i in range(n):
        sizes.append(1)
    return sizes


lib.put.argtypes = [ctypes.c_int, ctypes.c_int,  ctypes.c_int,
                    ctypes.c_int, ctypes.c_int, ctypes.c_void_p,
                    ctypes.POINTER(ctypes.c_int)]


def put(var_id, kstep, field):
    sizes = get_sizes(field)
    length = sizes[0]*sizes[1]*sizes[2]
    error = c_int(0)
    p_field = field.ctypes.data
    lib.put(var_id, kstep, sizes[0], sizes[1], sizes[2],
            p_field, error)
    return error.value


lib.get.argtypes = [ctypes.c_int, ctypes.c_int,  ctypes.c_int, ctypes.c_int,
                    ctypes.c_int, ctypes.c_void_p,
                    ctypes.POINTER(ctypes.c_int)]


def get(var_id, kstep, field):
    sizes = get_sizes(field)
    length = sizes[0]*sizes[1]*sizes[2]
    error = c_int(0)
    p_field = field.ctypes.data
    lib.get(var_id, kstep, sizes[0], sizes[1], sizes[2], p_field, error)
    return error.value
