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


"""OASIS grid data and methods"""

import numpy
import ctypes
from ctypes import c_int, cdll, CDLL

cdll.LoadLibrary("liboasis.C.bindings.so")
LIB=CDLL("liboasis.C.bindings.so")

LIB.start_grids_writing.argtypes=[ctypes.POINTER(ctypes.c_int)]

def start_grids_writing():
    kinfo = c_int(0)
    LIB.start_grids_writing(kinfo)
    return kinfo.value

LIB.write_grid.argtypes=[ctypes.c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int]

def write_grid(cgrid, nx, ny, lon, lat, partid):
    lon = numpy.asfortranarray(lon, dtype=numpy.float64)
    lat = numpy.asfortranarray(lat, dtype=numpy.float64)
    p_lon = lon.ctypes.data
    p_lat = lat.ctypes.data
    if lon.ndim != 2:
        raise pyoasis.PyOasisException("Write grid: lon and lat have to be 2D arrays")
    if lon.shape != lat.shape:
        raise pyoasis.PyOasisException("Write grid: lon and lat shape not conforming")
    nx_loc = lon.shape[0]
    ny_loc = lon.shape[1]
    LIB.write_grid(cgrid.encode(), nx, ny, nx_loc, ny_loc, p_lon, p_lat, partid)

    
LIB.write_corner.argtypes=[ctypes.c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int]

def  write_corner(cgrid, nx, ny, clo, cla, partid):
    clo = numpy.asfortranarray(clo, dtype=numpy.float64)
    cla = numpy.asfortranarray(cla, dtype=numpy.float64)
    p_clo = clo.ctypes.data
    p_cla = cla.ctypes.data
    if clo.ndim != 3:
        raise pyoasis.PyOasisException("Write grid: clo and cla have to be 3D arrays")
    if clo.shape != cla.shape:
        raise pyoasis.PyOasisException("Write corner: clo and cla shape not conforming")
    nx_loc = clo.shape[0]
    ny_loc = clo.shape[1]
    ncrn   = clo.shape[2]
    LIB.write_corner(cgrid.encode(), nx, ny, ncrn, nx_loc, ny_loc, p_clo, p_cla, partid)


LIB.write_mask.argtypes=[ctypes.c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_int]

def write_mask(cgrid, nx, ny, mask, partid):
    mask = numpy.asfortranarray(mask, dtype=numpy.int32)
    p_mask = mask.ctypes.data
    if mask.ndim != 2:
        raise pyoasis.PyOasisException("Write mask: maks has to be a 2D arrays")
    nx_loc = mask.shape[0]
    ny_loc = mask.shape[1]
    LIB.write_mask(cgrid.encode(), nx, ny, nx_loc, ny_loc, p_mask, partid)


LIB.write_frac.argtypes=[ctypes.c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_int]

def write_frac(cgrid, nx, ny, frac, partid):
    frac = numpy.asfortranarray(frac, dtype=numpy.float64)
    p_frac = frac.ctypes.data
    if frac.ndim != 2:
        raise pyoasis.PyOasisException("Write frac: frac has to be a 2D arrays")
    nx_loc = frac.shape[0]
    ny_loc = frac.shape[1]
    LIB.write_frac(cgrid.encode(), nx, ny, nx_loc, ny_loc, p_frac, partid)


LIB.write_area.argtypes=[ctypes.c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_int]

def write_area(cgrid, nx, ny, area, partid):
    area = numpy.asfortranarray(area, dtype=numpy.float64)
    p_area = area.ctypes.data
    if area.ndim != 2:
        raise pyoasis.PyOasisException("Write area: area has to be a 2D arrays")
    nx_loc = area.shape[0]
    ny_loc = area.shape[1]
    LIB.write_area(cgrid.encode(), nx, ny, nx_loc, ny_loc, p_area, partid)

def terminate_grids_writing():
    LIB.terminate_grids_writing()
