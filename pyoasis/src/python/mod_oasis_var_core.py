#!/usr/bin/python3

"""OASIS variable data and methods"""

from enum import Enum
import ctypes
from ctypes import cdll, CDLL, c_int, c_char_p


class OasisVarParameters(Enum):
    """"""  
    OASIS_DOUBLE = 8


cdll.LoadLibrary("libpyoasiscore.so")
LIB = CDLL("libpyoasiscore.so")


LIB.def_var.argtypes = [ctypes.POINTER(ctypes.c_int), c_char_p, ctypes.c_int,
                        ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int,
                        ctypes.POINTER(ctypes.c_int), ctypes.c_int,
                        ctypes.POINTER(ctypes.c_int)]


def def_var(id_part, cdport, id_var_nodims1, id_var_nodims2, kinout):
    """The OASIS user interface to define variables"""
    id_nports = c_int(0)
    id_var_shape = c_int(0)
    kinfo = c_int(0)
    id_var_shape = c_int(0)
    LIB.def_var(id_nports, cdport.encode(), id_part, id_var_nodims1,
                id_var_nodims2, kinout, 0, id_var_shape, 
                OasisVarParameters.OASIS_DOUBLE.value, kinfo)
    return (id_nports.value, kinfo.value)
