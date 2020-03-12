#!/usr/bin/python3

"""OASIS send/receive (put/get) user interfaces"""

import ctypes
from ctypes import c_int, cdll, CDLL


cdll.LoadLibrary("libpyoasiscore.so")
LIB = CDLL("libpyoasiscore.so")


def get_sizes(field):
    """Creates an array containing the dimensions of multidimensional fields"""
    sizes = list(field.shape)
    n_dimensions_left = 3 - len(sizes)
    for i in range(n_dimensions_left):
        sizes.append(1)
    return sizes


LIB.put.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_int,
                    ctypes.c_int, ctypes.c_int, ctypes.c_void_p,
                    ctypes.POINTER(ctypes.c_int)]


def put(var_id, kstep, field):
    """Send 8-byte multidimensional field"""
    sizes = get_sizes(field)
    error = c_int(0)
    p_field = field.ctypes.data
    LIB.put(var_id, kstep, sizes[0], sizes[1], sizes[2],
            p_field, error)
    return error.value


LIB.get.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int,
                    ctypes.c_int, ctypes.c_void_p,
                    ctypes.POINTER(ctypes.c_int)]


def get(var_id, kstep, field):
    """Receive 8-byte multidimensional field"""
    sizes = get_sizes(field)
    error = c_int(0)
    p_field = field.ctypes.data
    LIB.get(var_id, kstep, sizes[0], sizes[1], sizes[2], p_field, error)
    return error.value
