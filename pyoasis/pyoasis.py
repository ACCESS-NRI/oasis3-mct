#!/usr/bin/python3

import numpy
from mpi4py import MPI

from ctypes import *
import ctypes

from enum import Enum

import mod_oasis_method_core
import mod_oasis_auxiliary_routines_core
import mod_oasis_sys_core
import mod_oasis_part_core
import mod_oasis_var_core
import mod_oasis_getput_interface_core


class params(Enum):
    OASIS_REAL=4
    OASIS_OUT=20
    OASIS_IN=21
    

# pyoasis.Array: array of doubles in Fortran ordering
def Array(data):
    return numpy.asfortranarray(data, dtype=numpy.float64)

def IntArray(data):
    return numpy.asfortranarray(data, dtype=numpy.int32)

def OasisException(text):
    return Exception(text)

def OasisException(text, error):
    return OasisException(text+" ("+str(error)+")")


class Component:
    def __init__(self, i_name, coupled=True, i_communicator=MPI.COMM_WORLD):
        self.name = i_name
        self.communicator=i_communicator
        rv = mod_oasis_method_core.init_comp(self.name, coupled, self.communicator)
        error = rv[1]
        if(error < 0):
            raise OasisException("Error initialising component "+self.name, error)
        self.id = rv[0]
    def get_name(self):
        return self.name
    def get_id(self):
        return self.id
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
    def get_comm_size(self):
        return mod_oasis_method_core.get_comm_size(self.communicator.py2f());
    def get_comm_rank(self):
        return mod_oasis_method_core.get_comm_rank(self.communicator.py2f());
    def get_localcomm_size(self):
        return mod_oasis_method_core.get_comm_size(self.get_localcomm());
    def get_localcomm_rank(self):
        return mod_oasis_method_core.get_comm_rank(self.get_localcomm());
     

def terminate():
    error = mod_oasis_method_core.terminate()
    if(error < 0):
        raise OasisException("Error in terminate", error)


# oasis_abort instead of simply abort because there
# was a clash with another function name
def oasis_abort(comp_id, routine, message, filename, line, error):
    mod_oasis_sys_core.oasis_abort(component_id, routine, message, filename, line, error)


class Partition:
    def set(self, parameters):
        rv = mod_oasis_part_core.def_partition(parameters)
        error = rv[1]
        if (error < 0):
            raise OasisException("Error in def_partition", error)
        self.id = rv[0]

class SerialPartition(Partition):
    def __init__(self, size):
        parameters=IntArray([0, 0, size])
        self.set(parameters)

class ApplePartition(Partition):
    def __init__(self, offset, size):
        parameters=IntArray([1, offset, size]);
        self.set(parameters)        

class BoxPartition(Partition):
    def __init__(self, global_offset, local_extent_x, local_extent_y, global_extent_x):
        parameters=IntArray([2, global_offset, local_extent_x, local_extent_y, global_extent_x]);
        self.set(parameters)
        
class OrangePartition(Partition):
    def __init__(self, offsets, extents):
        n=len(offsets)
        if(len(extents)!=n):
          raise OasisException("The number of offsets must be the same as the number of extents")  
        parameters1=[3, n]
        for i in range(n):
          parameters1.append(offsets[i])
          parameters1.append(extents[i])
        parameters2=IntArray(parameters1)
        self.set(parameters2)
        
class PointsPartition(Partition):
    def __init__(self, global_indices):
        parameters1=[4, len(global_indices)]
        for index in global_indices:
          parameters1.append(index)
        parameters2=IntArray(parameters1)
        self.set(parameters2)

class Var:
    def __init__(self, i_id_part, cdport, i_id_var_nodims1,
                 i_id_var_nodims2, i_kinout, i_ktype):
        id_part = i_id_part
        self.name = cdport
        id_var_nodims1 = i_id_var_nodims1
        id_var_nodims2 = i_id_var_nodims2
        kinout = i_kinout
        ktype = i_ktype
        rv = mod_oasis_var_core.def_var(id_part, self.name, id_var_nodims1, id_var_nodims2, kinout, ktype)
        error = rv[1]
        if(error < 0):
            raise OasisException("Error in def_var", error)
        self.id = rv[0]
    def put(self, kstep, field):
        mod_oasis_getput_interface_core.put(self.id, kstep, field)
    def get(self, kstep, field):
        mod_oasis_getput_interface_core.get(self.id, kstep, field)
