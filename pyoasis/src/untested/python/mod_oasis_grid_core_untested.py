#!/usr/bin/python

from ctypes import *
import ctypes

import numpy

cdll.LoadLibrary("liboasis.C.bindings.so")
lib=CDLL("liboasis.C.bindings.so")


lib.write_grid.argtypes=[c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_double), ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_double), ctypes.c_int]
def write_grid(cgrid, nx, ny, nlon1, nlon2, lon, nlat1, nlat2, lat, partid):
    lib.write_grid(cgrid, nx, ny, nlon1, nlon2, lon, nlat1, nlat2, lat, partid)

lib.write_corner.argtypes=[c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_double), ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_double), ctypes.c_int]
def  write_corner(cgrid, nx, ny, nc, nclon1, nclon2, nclon3, clon, nclat1, nclat2, nclat3, clat, partid):
    lib.write_corner(cgrid, nx, ny, nc, nclon1, nclon2, nclon3, clon, nclat1, nclat2, nclat3, clat, partid)
        
lib.write_mask.argtypes=[c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_int)]   
def write_mask(cgrid, nx, ny, nmask1, nmask2, mask, partid):
    lib.write_mask(cgrid.encode(), nx, ny, nmask1, nmask2, mask, partid)
    
lib.write_area.argtypes=[c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_double), ctypes.c_int]
def write_area(cgrid, nx, ny, narea1, narea2, area, partid):
    lib.write_area(cgrid.encode(), nx, ny, narea1, narea2, area, partid)

def terminate_grids_writing():
    lib.terminate_grids_writing()
