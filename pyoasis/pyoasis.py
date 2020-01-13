#!/usr/bin/python

import numpy
from mpi4py import MPI


import mod_oasis_method_core
import mod_oasis_auxiliary_routines_core
import mod_oasis_sys_core
import mod_oasis_part_core
import mod_oasis_var_core
import mod_oasis_getput_interface_core
import mod_oasis_grid_core


# pyoasis.Array: array of doubles in Fortran ordering
def Array(data):
    return numpy.asfortranarray(data, dtype=numpy.float64)


def OasisException(text, error):
    return Exception(text+" ("+str(error)+")")


class Component:
    id=0
    def __init__(self, i_name, coupled=False, communicator=MPI.COMM_WORLD):
        name = i_name
        rv = mod_oasis_method_core.init_comp(name, coupled, communicator)
        error = rv[1]
        if(error < 0):
            raise OasisException("Error initialising component "+name, error)
        id = rv[0]
    def get_localcomm(self):
        rv = mod_oasis_auxiliary_routines_core.get_localcomm()
        error = rv[1]
        if(error < 0):
            raise OasisException("Error in get_localcomm", error)
        localcomm = rv[0]
        return localcomm
    def create_couplcomm(self, icpl, allcomm):
        rv = mod_oasis_auxiliary_routines_core.create_couplcomm(icpl, allcomm)
        error = rv[1]
        if(error < 0):
            raise OasisException("Error in get_couplcomm", error)
        couplcomm = rv[0]
        return couplcomm
    def set_couplcomm(self, localcomm):
        error = mod_oasis_auxiliary_routines_core.set_couplcomm(localcomm)
        if(error < 0):
            raise OasisException("Error in set_couplcomm", error)
    def get_intercomm(self, localcomm):
        error = mod_oasis_auxiliary_routines_core.get_intercomm(localcomm)
        if(error < 0):
            raise OasisException("Error in get_intercomm", error)
    def get_intracomm(self, localcomm):
        error = mod_oasis_auxiliary_routines_core.get_intracomm(localcomm)
        if(error < 0):
            raise OasisException("Error in get_intracomm", error)
    def enddef(self):
        error = mod_oasis_method_core.enddef();
        if(error < 0):
            raise OasisException("Error in enddef", error)
    def get_id(self):
        return id

def terminate():
    error = mod_oasis_method_core.terminate()
    if(error < 0):
        raise OasisException("Error in terminate", error)


# oasis_abort instead of simply abort because there
# was a clash with another function name
def oasis_abort(comp_id, routine, message, filename, line, error):
    mod_oasis_sys_core.oasis_abort(component_id, routine, message, filename, line, error)


class Partition:
    def __init__(self, i_ig_size, i_name):
        ig_size = i_ig_size
        name = i_name
        rv = mod_oasis_part_core.def_partition(ig_size, name)
        error = rv[2]
        if (error < 0):
            raise OasisException("Error in def_partition", error)
        id_part = rv[0]
        kparal = rv[1]


class Var:
    def __init__(self, i_id_part, i_cdport, i_id_var_nodims1,
                 i_id_var_nodims2, i_kinout, i_n, i_ktype):
        id_part = i_id_part
        cdport = i_cdport
        id_var_nodims1 = i_id_var_nodims1
        id_var_nodims2 = i_id_var_nodims2
        kinout = i_kinout
        n = i_n
        ktype = i_ktype
        rv = mod_oasis_var_core.def_var(id_part, cdport, id_var_nodims1, id_var_nodims2, kinout, n, ktype)
        error = rv[2]
        if(error < 0):
            raise OasisException("Error in def_var", error)
        var_id = rv[0]
        id_var_shape = rv[1]

    def put(kstep, sizes, field):
        mod_oasis_getput_interface_core.put(var_id, kstep, sizes, field)

    def get(kstep, sizes, field):
        mod_oasis_getput_interface_core.get(var_id, kstep, sizes, field)
        

# This is only a temporary wrapping.
# These functions will be combined into objects.
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
