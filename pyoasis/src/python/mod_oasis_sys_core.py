#!/usr/bin/python3

"""System type methods"""

import ctypes
from ctypes import cdll, CDLL, c_int, c_char_p

cdll.LoadLibrary("libpyoasiscore.so")
LIB = CDLL("libpyoasiscore.so")


LIB.oasis_abort.argtypes = [ctypes.c_int, c_char_p, c_char_p, c_char_p,
                            c_int, c_int]


def oasis_abort(comp_id, routine, message, filename, line, error):
    """OASIS abort method, publicly available to users"""
    LIB.oasis_abort(comp_id, routine.encode(), message.encode(),
                    filename.encode(), line, error)
