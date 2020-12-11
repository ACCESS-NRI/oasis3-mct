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
import numpy

cdll.LoadLibrary("liboasis.cbind.so")
LIB = CDLL("liboasis.cbind.so")

LIB.oasis_c_get_localcomm.argtypes = [ctypes.POINTER(ctypes.c_int),
                              ctypes.POINTER(ctypes.c_int)]


def get_localcomm():
    """OASIS user query for the local MPI communicator"""
    localcomm = c_int(0)
    kinfo = c_int(0)
    LIB.oasis_c_get_localcomm(localcomm, kinfo)
    return localcomm.value, kinfo.value


LIB.oasis_c_create_couplcomm.argtypes = [ctypes.c_int, ctypes.c_int,
                                 ctypes.POINTER(ctypes.c_int),
                                 ctypes.POINTER(ctypes.c_int)]


def create_couplcomm(icpl, allcomm):
    """OASIS user call to create a new communicator"""
    cplcomm = c_int(0)
    kinfo = c_int(0)
    LIB.oasis_c_create_couplcomm(icpl, allcomm, cplcomm, kinfo)
    return cplcomm.value, kinfo.value


LIB.oasis_c_set_couplcomm.argtypes = [ctypes.c_int,
                              ctypes.POINTER(ctypes.c_int)]


def set_couplcomm(couplcomm):
    """OASIS user call to specify a local communicator"""
    kinfo = c_int(0)
    LIB.oasis_c_set_couplcomm(couplcomm.py2f(), kinfo)
    return kinfo.value


LIB.oasis_c_get_intercomm.argtypes = [ctypes.POINTER(ctypes.c_int), ctypes.c_char_p,
                              ctypes.POINTER(ctypes.c_int)]


def get_intercomm(cdnam):
    """OASIS user interface to establish an intercomm communicator between the root of two models"""
    new_comm = c_int(0)
    kinfo = c_int(0)
    LIB.oasis_c_get_intercomm(new_comm, cdnam.encode(), kinfo)
    return new_comm.value, kinfo.value


LIB.oasis_c_get_intracomm.argtypes = [ctypes.POINTER(ctypes.c_int), ctypes.c_char_p,
                              ctypes.POINTER(ctypes.c_int)]


def get_intracomm(cdnam):
    """OASIS user interface to establish an intracomm communicator between the root of two models"""
    new_comm = c_int(0)
    kinfo = c_int(0)
    LIB.oasis_c_get_intracomm(new_comm, cdnam.encode(), kinfo)
    return new_comm.value, kinfo.value


LIB.oasis_c_mpi_get_comm_size.argtypes = [ctypes.c_int, ctypes.POINTER(ctypes.c_int),
                              ctypes.POINTER(ctypes.c_int)]


def get_comm_size(communicator):
    """Returns the size of a communicator."""
    comm_size = c_int(0)
    kinfo = c_int(0)
    LIB.oasis_c_mpi_get_comm_size(communicator, comm_size, kinfo)
    return comm_size.value, kinfo.value


LIB.oasis_c_mpi_get_comm_rank.argtypes = [ctypes.c_int, ctypes.POINTER(ctypes.c_int),
                              ctypes.POINTER(ctypes.c_int)]


def get_comm_rank(communicator):
    """Returns the rank in a communicator."""
    comm_rank = c_int(0)
    kinfo = c_int(0)
    LIB.oasis_c_mpi_get_comm_rank(communicator, comm_rank, kinfo)
    return comm_rank.value, kinfo.value


LIB.oasis_c_set_debug.argtypes = [ctypes.c_int, ctypes.POINTER(ctypes.c_int)]


def set_debug(debug):
    """Set debug level"""
    kinfo = c_int(0)
    LIB.oasis_c_set_debug(debug, kinfo)
    return kinfo.value


LIB.oasis_c_get_debug.argtypes = [ctypes.POINTER(ctypes.c_int),
                          ctypes.POINTER(ctypes.c_int)]


def get_debug():
    """Get debug level"""
    debug = c_int(0)
    kinfo = c_int(0)
    LIB.oasis_c_get_debug(debug, kinfo)
    return debug.value, kinfo.value


LIB.oasis_c_put_inquire.argtypes = [ctypes.c_int, ctypes.c_int,
                            ctypes.POINTER(ctypes.c_int)]


def put_inquire(varid, msec):
    """Gives put return code expected at a specified time
    for a given variable"""
    kinfo = c_int(0)
    LIB.oasis_c_put_inquire(varid, msec, kinfo)
    return kinfo.value


LIB.oasis_c_get_ncpl.argtypes = [ctypes.c_int, ctypes.POINTER(ctypes.c_int),
                         ctypes.POINTER(ctypes.c_int)]


def get_ncpl(varid):
    """Returns the number of unique couplings associated with
    a variable."""
    ncpl = c_int(0)
    kinfo = c_int(0)
    LIB.oasis_c_get_ncpl(varid, ncpl, kinfo)
    return ncpl.value, kinfo.value


LIB.oasis_c_get_freqs.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_int,
                          ctypes.c_void_p, ctypes.POINTER(ctypes.c_int)]


def get_freqs(varid, mop, ncpl):
    """Returns the coupling periods for a given variable."""
    cpl_freqs_p = numpy.zeros(ncpl, dtype=numpy.int32)
    kinfo = c_int(0)
    LIB.oasis_c_get_freqs(varid, c_int(mop), c_int(ncpl), cpl_freqs_p.ctypes.data,
                  kinfo)
    cpl_freqs = cpl_freqs_p.tolist()
    return cpl_freqs, kinfo.value


def get_freqs_array(varid, mop):
    """Returns the coupling periods for a given variable."""
    ncpl, kinfo = get_ncpl(varid)
    return get_freqs(varid, mop, ncpl)
