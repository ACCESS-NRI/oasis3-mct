#!/usr/bin/python3

"""Wrapper in Python for OASIS"""

from enum import Enum
import numpy
from mpi4py import MPI

import mod_oasis_method_core
import mod_oasis_auxiliary_routines_core
import mod_oasis_sys_core
import mod_oasis_part_core
import mod_oasis_var_core
import mod_oasis_getput_interface_core


class OasisParameters(Enum):
    """Enumeration containing different OASIS parameters"""
    OASIS_REAL = 4
    OASIS_OUT = 20
    OASIS_IN = 21


# pyoasis.Array: array of doubles in Fortran ordering
def FloatArray(data):
    """Creates a numpy array containing doubles in Fortran ordering."""
    return numpy.asfortranarray(data, dtype=numpy.float64)


def IntArray(data):
    """Creates a numpy array containing doubles in Fortran ordering."""
    return numpy.asfortranarray(data, dtype=numpy.int32)


def OasisException(text, error):
    """Creates an exception with an error code."""
    return OasisException(text+" ("+str(error)+")")


class Component(object):
    """Class handling a component."""
    def __init__(self, i_name, coupled=True, i_communicator=MPI.COMM_WORLD):
        """Constructor"""
        self.name = i_name
        self.communicator = i_communicator
        return_value = mod_oasis_method_core.init_comp(self.name, coupled,
                                                       self.communicator)
        error = return_value[1]
        if error < 0:
            raise OasisException("Error initialising component "+self.name,
                                 error)
        self.id_component = return_value[0]

    def get_name(self):
        """Returns component name."""
        return self.name

    def get_id(self):
        """Returns component ID."""
        return self.id_component

    def get_localcomm(self):
        """Returns local communicator."""
        return_value = mod_oasis_auxiliary_routines_core.get_localcomm()
        error = return_value[1]
        if error < 0:
            raise OasisException("Error in get_localcomm", error)
        localcomm = return_value[0]
        return localcomm

    def create_couplcomm(self, coupling_process_flag, comm):
        """Creates coupling communicator."""
        return_value = mod_oasis_auxiliary_routines_core.create_couplcomm(
            coupling_process_flag, comm)
        error = return_value[1]
        if error < 0:
            raise OasisException("Error in get_couplcomm", error)
        couplcomm = return_value[0]
        return couplcomm

    def set_couplcomm(self, localcomm):
        """Sets coupling communicator."""
        error = mod_oasis_auxiliary_routines_core.set_couplcomm(localcomm)
        if error < 0:
            raise OasisException("Error in set_couplcomm", error)

    def get_intercomm(self, new_communicator, other_model_name):
        """Gets an intercomm communicator between the root of two models."""
        error = mod_oasis_auxiliary_routines_core.get_intercomm(new_communicator, other_model_name)
        if error < 0:
            raise OasisException("Error in get_intercomm", error)

    def get_intracomm(self, new_communicator, other_model_name):
        """Gets an intracomm communicator between the root of two models."""
        error = mod_oasis_auxiliary_routines_core.get_intracomm(new_communicator, other_model_name)
        if error < 0:
            raise OasisException("Error in get_intracomm", error)

    def enddef(self):
        """Ends the initialisation of the component."""
        error = mod_oasis_method_core.enddef()
        if error < 0:
            raise OasisException("Error in enddef", error)

    def get_comm_size(self):
        """Gets the size of the global communicator."""
        return mod_oasis_auxiliary_routines_core.get_comm_size(self.communicator.py2f())

    def get_comm_rank(self):
        """Gets the rank in the global comminucator."""
        return mod_oasis_auxiliary_routines_core.get_comm_rank(self.communicator.py2f())

    def get_localcomm_size(self):
        """Gets the size of the local communicator."""
        return mod_oasis_auxiliary_routines_core.get_comm_size(self.get_localcomm())

    def get_localcomm_rank(self):
        """Gets the rank in the local communicator."""
        return mod_oasis_auxiliary_routines_core.get_comm_rank(self.get_localcomm())


def terminate():
    """Ends the coupling."""
    error = mod_oasis_method_core.terminate()
    if error < 0:
        raise OasisException("Error in terminate", error)


# oasis_abort instead of simply abort because there
# was a clash with another function name
def oasis_abort(component_id, routine, message, filename, line, error):
    """Aborts OASIS."""
    mod_oasis_sys_core.oasis_abort(component_id, routine, message, filename,
                                   line, error)


class Partition(object):
    """Base class handling a partition"""
    def set(self, parameters):
        """Sets up the partition. Will be called by the inherited classes."""
        return_value = mod_oasis_part_core.def_partition(parameters)
        error = return_value[1]
        if error < 0:
            raise OasisException("Error in def_partition", error)
        self.partition_id = return_value[0]
    def get_id(self):
        """Returns partition ID."""
        return self.partition_id


class SerialPartition(Partition):
    """Serial partition"""
    def __init__(self, size):
        """Constructor"""
        parameters = IntArray([0, 0, size])
        self.set(parameters)


class ApplePartition(Partition):
    """Apple partition"""
    def __init__(self, offset, size):
        """Constructor"""
        parameters = IntArray([1, offset, size])
        self.set(parameters)


class BoxPartition(Partition):
    """Box partition"""
    def __init__(self, global_offset, local_extent_x, local_extent_y,
                 global_extent_x):
        """Constructor"""
        parameters = IntArray([2, global_offset, local_extent_x,
                               local_extent_y, global_extent_x])
        self.set(parameters)


class OrangePartition(Partition):
    """Orange partion"""
    def __init__(self, offsets, extents):
        """Constructor"""
        n_offsets = len(offsets)
        if len(extents) != n_offsets:
            raise OasisException("Number of offsets != number of extents", -1)
        parameters1 = [3, n_offsets]
        for i in range(n_offsets):
            parameters1.append(offsets[i])
            parameters1.append(extents[i])
        parameters2 = IntArray(parameters1)
        self.set(parameters2)


class PointsPartition(Partition):
    """Points partition"""
    def __init__(self, global_indices):
        """Constructor"""
        parameters1 = [4, len(global_indices)]
        for index in global_indices:
            parameters1.append(index)
        parameters2 = IntArray(parameters1)
        self.set(parameters2)


class Var:
    """Class handling variable data"""
    def __init__(self, i_id_part, cdport, i_id_var_nodims1,
                 i_id_var_nodims2, i_kinout, i_ktype):
        """Constructor"""
        id_part = i_id_part
        self.name = cdport
        id_var_nodims1 = i_id_var_nodims1
        id_var_nodims2 = i_id_var_nodims2
        kinout = i_kinout
        ktype = i_ktype
        return_value = mod_oasis_var_core.def_var(id_part, self.name, id_var_nodims1,
                                                  id_var_nodims2, kinout, ktype)
        error = return_value[1]
        if error < 0:
            raise OasisException("Error in def_var", error)
        self.var_id = return_value[0]

    def get_id(self):
        """Returns ID of variable data."""
        return self.var_id

    def put(self, kstep, field):
        """Sends data to another model."""
        mod_oasis_getput_interface_core.put(self.var_id, kstep, field)

    def get(self, kstep, field):
        """Gets data from another model."""
        mod_oasis_getput_interface_core.get(self.var_id, kstep, field)
