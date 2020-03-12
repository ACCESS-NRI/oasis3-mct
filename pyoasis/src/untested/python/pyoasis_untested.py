#!/usr/bin/python3

import mod_oasis_auxiliary_routines_core
import mod_oasis_grid_core


class Component(object):
    def set_couplcomm(self, localcomm):
        error = mod_oasis_auxiliary_routines_core.set_couplcomm(localcomm)
        if error < 0:
            raise OasisException("Error in set_couplcomm", error)

    def get_intercomm(self, other_model_name):
        return_value = mod_oasis_auxiliary_routines_core.get_intercomm(other_model_name)
        new_communicator=return_value[0]
        error=return_value[1]
        if error < 0:
            raise OasisException("Error in get_intercomm", error)
        return new_communicator

    def get_intracomm(self, other_model_name):
        return_value = mod_oasis_auxiliary_routines_core.get_intracomm(other_model_name)
        new_communicator=return_value[0]
        error=return_value[1]
        if error < 0:
            raise OasisException("Error in get_intracomm", error)
        return new_communicator



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
