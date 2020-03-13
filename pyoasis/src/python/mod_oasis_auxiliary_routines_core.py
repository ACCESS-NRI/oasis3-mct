#!/usr/bin/python3

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


"""Auxiliary OASIS user interfaces"""

import ctypes
from ctypes import cdll, CDLL, c_int



cdll.LoadLibrary("libpyoasiscore.so")
LIB = CDLL("libpyoasiscore.so")


LIB.get_localcomm.argtypes = [ctypes.POINTER(ctypes.c_int),
                              ctypes.POINTER(ctypes.c_int)]


def get_localcomm():
    """OASIS user query for the local MPI communicator"""
    localcomm = c_int(0)
    error = c_int(0)
    LIB.get_localcomm(localcomm, error)
    return (localcomm.value, error.value)

LIB.create_couplcomm.argtypes = [ctypes.c_int, ctypes.c_int,
                                 ctypes.POINTER(ctypes.c_int),
                                 ctypes.POINTER(ctypes.c_int)]


def create_couplcomm(icpl, allcomm):
    """OASIS user call to create a new communicator"""
    cplcomm = c_int(0)
    error = c_int(0)
    LIB.create_couplcomm(icpl, allcomm, cplcomm, error)
    return (cplcomm.value, error.value)


LIB.set_couplcomm.argtypes = [ctypes.c_int,
                              ctypes.POINTER(ctypes.c_int)]


def set_couplcomm(localcomm):
    """OASIS user call to specify a local communicator"""
    new_comm = c_int(0)
    error = c_int(0)
    LIB.set_couplcomm(localcomm, error)
    return (new_comm.value, error.value)


LIB.get_intercomm.argtypes = [ctypes.c_int, ctypes.c_char_p,
                              ctypes.POINTER(ctypes.c_int)]


def get_intercomm(cdnam):
    """OASIS user interface to establish an intercomm communicator between the root of two models"""
    new_comm = c_int(0)
    error = c_int(0)
    LIB.get_intercomm(new_comm, cdnam.encode(), error)
    return (new_comm.value, error.value)


LIB.get_intracomm.argtypes = [ctypes.c_int, ctypes.c_char_p,
                              ctypes.POINTER(ctypes.c_int)]


def get_intracomm(new_comm, cdnam):
    """OASIS user interface to establish an intracomm communicator between the root of two models"""
    error = c_int(0)
    LIB.get_intracomm(new_comm, cdnam.encode(), error)
    return error.value


LIB.get_comm_size.argtypes = [ctypes.c_int, ctypes.POINTER(ctypes.c_int),
                              ctypes.POINTER(ctypes.c_int)]


def get_comm_size(communicator):
    """Returns the size of a communicator."""
    comm_size = c_int(0)
    error = c_int(0)
    LIB.get_comm_size(communicator, comm_size, error)
    return comm_size.value


LIB.get_comm_rank.argtypes = [ctypes.c_int, ctypes.POINTER(ctypes.c_int),
                              ctypes.POINTER(ctypes.c_int)]


def get_comm_rank(communicator):
    """Returns the rank in a communicator."""
    comm_rank = c_int(0)
    error = c_int(0)
    LIB.get_comm_rank(communicator, comm_rank, error)
    return comm_rank.value
