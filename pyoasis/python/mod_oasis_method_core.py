#!/usr/bin/python3

"""High level OASIS user interfaces"""

import ctypes
from ctypes import cdll, CDLL, c_int, c_char_p


cdll.LoadLibrary("libpyoasiscore.so")
LIB = CDLL("libpyoasiscore.so")


LIB.init_comp.argtypes = [ctypes.POINTER(ctypes.c_int), c_char_p,
                          ctypes.POINTER(ctypes.c_int), ctypes.c_bool,
                          ctypes.c_int]


def init_comp(comp_name, coupled, communicator):
    """OASIS user init method"""
    comp_id = c_int(0)
    error = c_int(0)
    LIB.init_comp(comp_id, comp_name.encode(), error, coupled,
                  communicator.py2f())
    return (comp_id.value, error.value)


LIB.enddef.argtypes = [ctypes.POINTER(ctypes.c_int)]


def enddef():
    """OASIS user interface specifying the OASIS definition phase is complete"""
    error = c_int(0)
    LIB.enddef(error)
    return error.value


LIB.terminate.argtypes = [ctypes.POINTER(ctypes.c_int)]


def terminate():
    """OASIS user finalize method"""
    error = c_int(0)
    LIB.terminate(error)
    return error.value
