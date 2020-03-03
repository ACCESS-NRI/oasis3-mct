#!/usr/bin/python3

import mod_oasis_auxiliary_routines_core
import mod_oasis_grid_core


def OasisException(text):
    return Exception(text)

def OasisException(text, error):
    return OasisException(text+" ("+str(error)+")")


def write_grid(cgrid, nx, ny, nlon1, nlon2, lon, nlat1, nlat2, lat, partid=-1):
    mod_oasis_grid_core.write_grid(cgrid, nx, ny, nlon1, nlon2, lon, nlat1, nlat2, lat, partid)
    
def  write_corner(cgrid, nx, ny, nc, nclon1, nclon2, nclon3, clon, nclat1, nclat2, nclat3, clat, partid):
    mod_oasis_grid_core.write_corner(cgrid, nx, ny, nc, nclon1, nclon2, nclon3, clon, nclat1, nclat2, nclat3, clat, partid)
    
def write_area(cgrid, nx, ny, narea1, narea2, area, partid=-1):
    mod_oasis_grid_core.write_area(cgrid, nx, ny, narea1, narea2, area, partid)

def terminate_grids_writing():
    mod_oasis_grid_core.terminate_grids_writing()
    
def set_debug(debug):
    error=mod_oasis_auxiliary_routines_core.set_debug(debug)
    if(error<0):
        raise OasisException("Error in set_debug", error)
    
def get_debug():
    rv=mod_oasis_auxiliary_routines_core.get_debug()
    error=rv[0]
    if(error<0):
        raise OasisException("Error in get_debug", error)
    debug=rv[1]
    return debug

def put_inquire(varid, msec):
    error=mod_oasis_auxiliary_routines_core.put_inquire(varid, msec)
    if(error<0):
        raise OasisException("Error in put_inquire", error)    
    
def get_ncpl(varid):
    rv=get_ncpl(varid)
    error=rv[1]
    if(error<0):
        raise OasisException("Error in get_ncpl", error)
    ncpl=rv[0]
    return ncpl

def get_freqs(varid, mop, ncpl, cpl_freqs):
    error=mod_oasis_auxiliary_routines_core.get_freqs(varid, mop, ncpl, cpl_freqs)
    if(error<0):
        raise OasisException("Error in get_freqs", error)   
