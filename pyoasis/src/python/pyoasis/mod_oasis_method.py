#!/usr/bin/env python3

# pyOASIS - A Python wrapper for OASIS
# Authors: Philippe Gambron, Rupert Ford
# Copyright (C) 2019 UKRI - STFC

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as 
# published by the Free Software Foundation, either version 3 of the 
# License, or any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.

# A copy of the GNU Lesser General Public License, version 3, is supplied
# with this program, in the file lgpl-3.0.txt. It is also available at 
# <https://www.gnu.org/licenses/lgpl-3.0.html>.


"""High level OASIS user interfaces"""

import ctypes
from ctypes import cdll, CDLL, c_int, c_char_p


cdll.LoadLibrary("liboasis.C.bindings.so")
LIB = CDLL("liboasis.C.bindings.so")


LIB.init_comp.argtypes = [ctypes.POINTER(ctypes.c_int), c_char_p,
                          ctypes.POINTER(ctypes.c_int), ctypes.c_bool,
                          ctypes.c_int]


def init_comp(comp_name, coupled, communicator):
    """OASIS user init method"""
    comp_id = c_int(0)
    error = c_int(0)
    LIB.init_comp(comp_id, comp_name.encode(), error, coupled,
                  communicator.py2f())
    return comp_id.value, error.value


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
