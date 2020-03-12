#!/usr/bin/python3

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
    """"""  
    OASIS_OUT = 20
    OASIS_IN = 21


# pyoasis.Array: array of doubles in Fortran ordering
def FloatArray(data):
    return numpy.asfortranarray(data, dtype=numpy.float64)


def IntArray(data):
    """Creates a numpy array containing doubles in Fortran ordering."""
    return numpy.asfortranarray(data, dtype=numpy.int32)


def OasisException(text, error):
    """Creates an exception with an error code."""
    return OasisException(text+" ("+str(error)+")")


class Component(object):
    """Component that will be coupled by OASIS

    :param string name: name of the component
    :param bool coupled: whether the component will be coupled (default: True)
    :param mpi4py.MPI.Intracomm communicator: global MPI communicator (default: MPI.COMM_WORLD)

    :raises OasisException: if OASIS is unable to initialise the component
    """
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
        """
        :returns: the name of the component
        """
        return self.name

    def get_id(self):
        """
        :returns: the interger number identifying the component
        """
        return self.id_component

    def get_localcomm(self):
        """
        :returns: the local communicator
        :raises OasisException: if OASIS is unable to return the local\
                                communicator 
        """
        return_value = mod_oasis_auxiliary_routines_core.get_localcomm()
        error = return_value[1]
        if error < 0:
            raise OasisException("Error in get_localcomm", error)
        localcomm = return_value[0]
        return localcomm

    def create_couplcomm(self, coupling_process_flag, comm):
        """
        Creates the coupling communicator.
        
        :param int coupling_process_flag: coupling prodess flag
        :param int comm: communicator

        :raises OasisException: if OASIS is unable to create the communicator

        """
        return_value = mod_oasis_auxiliary_routines_core.create_couplcomm(
            coupling_process_flag, comm)
        error = return_value[1]
        if error < 0:
            raise OasisException("Error in get_couplcomm", error)
        couplcomm = return_value[0]
        return couplcomm

    def enddef(self):
        """Ends the initialisation of the component."""
        error = mod_oasis_method_core.enddef()
        if error < 0:
            raise OasisException("Error in enddef", error)

    def get_comm_size(self):
        """
        :returns: the size of the global communicator.
        """
        return mod_oasis_auxiliary_routines_core.get_comm_size(self.communicator.py2f())

    def get_comm_rank(self):
        """
        :returns: the rank in the global comminucator
        """
        return mod_oasis_auxiliary_routines_core.get_comm_rank(self.communicator.py2f())

    def get_localcomm_size(self):
        """
        :returns: the size of the local communicator
        """
        return mod_oasis_auxiliary_routines_core.get_comm_size(self.get_localcomm())

    def get_localcomm_rank(self):
        """
        :returns: the rank in the local communicator
        """
        return mod_oasis_auxiliary_routines_core.get_comm_rank(self.get_localcomm())


def terminate():
    """
    Ends the coupling.

    :raises OasisException: if OASIS fails in terminating the coupling
    """
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
    """
    Serial partition
    
    :param int size:
    
    :raises OasisException: if OASIS fails to initialise the partition
    """
    def __init__(self, size):
        """Constructor"""
        parameters = IntArray([0, 0, size])
        self.set(parameters)


class ApplePartition(Partition):
    """
    Apple partition
 
    :param int offset:   
    :param int size:  

    :raises OasisException: if OASIS fails to initialise the partition
    """
    def __init__(self, offset, size):
        """Constructor"""
        parameters = IntArray([1, offset, size])
        self.set(parameters)


class BoxPartition(Partition):
    """
    Box partition
 
    :param int global_offset:   
    :param int local_extent_x:
    :param int local_extent_y:  
    :param int global_extent_x:
    :raises OasisException: if OASIS fails to initialise the partition
    """
    def __init__(self, global_offset, local_extent_x, local_extent_y,
                 global_extent_x):
        """Constructor"""
        parameters = IntArray([2, global_offset, local_extent_x,
                               local_extent_y, global_extent_x])
        self.set(parameters)


class OrangePartition(Partition):
    """
    Orange partition
 
    :param offsets:   
    :type offsets list of integers:
    :param extents:   
    :type extents list of integers:
    :raises OasisException: if OASIS fails to initialise the partition
    """
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
    """
    Orange partition
 
    :param global_indices: list containing the global indices of the \
                           points in the partition    
    :type global_induces list of integers:
    :raises OasisException: if OASIS fails to initialise the partition
    """
    def __init__(self, global_indices):
        """Constructor"""
        parameters1 = [4, len(global_indices)]
        for index in global_indices:
            parameters1.append(index)
        parameters2 = IntArray(parameters1)
        self.set(parameters2)


class Var:
    """
    Variable data

    :param int id_part: partition ID
    :param string cdport: name
    :raises OasisException: if OASIS is unable to initialise \
                            the variable data 
    """
    def __init__(self, i_id_part, cdport, i_id_var_nodims1,
                 i_id_var_nodims2, i_kinout):
        """Constructor"""
        id_part = i_id_part
        self.name = cdport
        id_var_nodims1 = i_id_var_nodims1
        id_var_nodims2 = i_id_var_nodims2
        kinout = i_kinout
        return_value = mod_oasis_var_core.def_var(id_part, self.name, id_var_nodims1,
                                                  id_var_nodims2, kinout)
        error = return_value[1]
        if error < 0:
            raise OasisException("Error in def_var", error)
        self.var_id = return_value[0]

    def get_id(self):
        """
        :returns: ID of variable data
        """
        return self.var_id

    def put(self, kstep, field):
        """
        Sends data to another model.
        :param int kstep: model time (in seconds)
        :param pyoasis.Array: field data
        """
        mod_oasis_getput_interface_core.put(self.var_id, kstep, field)

    def get(self, kstep, field):
        """
        Gets data from another model.
        :param int kstep: model time (in seconds)
        :param pyoasis.Array: field data
        """
        mod_oasis_getput_interface_core.get(self.var_id, kstep, field)
