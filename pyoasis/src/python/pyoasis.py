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


from enum import Enum
import numpy
from mpi4py import MPI

import mod_oasis_method_core
import mod_oasis_auxiliary_routines_core
import mod_oasis_sys_core
import mod_oasis_part_core
import mod_oasis_var_core
import mod_oasis_getput_interface_core


class OasisException(Exception):
    def __init__(self, text, error):
        super(OasisException, self).__init__(text + " (" + str(error)+ ")")

class PyOasisException(Exception):
    def __init__(self, text):
        super(PyOasisException, self).__init__(text)


class OasisParameters(Enum):
    """
    Enumeration of parameters used by OASIS (values: OASIS_OUT, \
    OASIS_IN)
    """  
    OASIS_OUT = 20
    OASIS_IN = 21


def Array(data):
    """
    Numpy array of double precision floating point numbers in Fortran ordering

    :param data: any object that can be used to initialise a numpy array

    :raises PyOasisException: if a Numpy array cannot be initialised
    """
    try:
        return numpy.asfortranarray(data, dtype=numpy.float64)
    except:
        raise PyOasisException("Unable to initialise the Numpy array")
    

class OasisException(Exception):
    """Exception from OASIS"""
    def __init__(self, text, error):
        super(OasisException, self).__init__(text + " (" + str(error)+ ")")

class PyOasisException(Exception):
    """Exception raised by pyOASIS"""
    def __init__(self, text):
        super(PyOasisException, self).__init__(text)
        
def check_types(types, arguments):
    """Checks the arguments of a function."""
    if len(arguments) != len(types):
        raise PyOasisException("The function requires "
                               +str(len(types))+" arguments.")
    i=0
    for (t, a) in zip(types, arguments):
        if t == list:
            for element in a:
                if type(element) != int:
                    raise PyOasisException(
                          "The elements of the list in argument "
                          +str(i)+" must be integers.")
        else:
           if type(a) != t:
               raise PyOasisException("Argument "+str(i)
                                      +" must be of type "+str(t)+".")

        i=i+1


class Component(object):
    """
    Component that will be coupled by OASIS

    :param string name: name of the component
    :param bool coupled: whether the component will be coupled (default: True)
    :param mpi4py.MPI.Intracomm communicator: global MPI communicator (default: MPI.COMM_WORLD)
    :raises OasisException: if OASIS is unable to initialise the component
    """
    def __init__(self, i_name, coupled=True, i_communicator=MPI.COMM_WORLD):
        """Constructor"""
        check_types([str, bool, MPI.Intracomm],
                    [i_name, coupled, i_communicator])
        if len(i_name)==0:
            raise PyOasisException("Component name empty.")
        
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
        :returns: the component identifier
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

    def create_couplcomm(self, icpl, allcomm=None):
        """
        Creates the coupling communicator.
        
        :param int icpl: coupling process flag
        :param int comm: communicator (default: local communicator)

        :raises OasisException: if OASIS is unable to create the coupling \
                                communicator

        """
        if allcomm is None:
            allcomm=self.get_localcomm()
        check_types([int, int], [icpl, allcomm]);
        if allcomm<0:
            raise PyOasisException("Communicator <0.")   

        return_value = mod_oasis_auxiliary_routines_core.create_couplcomm(icpl, 
                                                                          allcomm)
        error = return_value[1]
        if error < 0:
            raise OasisException("Error in get_couplcomm", error)
        cplcomm = return_value[0]
        return cplcomm

    def enddef(self):
        """
        Ends the initialisation of the component.

        :raises OasisException: if OASIS is unable to end the \
                                initialisation
        """
        error = mod_oasis_method_core.enddef()
        if error < 0:
            raise OasisException("Error in enddef", error)

    def get_comm_size(self):
        """
        :returns: the size of the global communicator
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

    :raises OasisException: if OASIS is unable to end the coupling
    """
    error = mod_oasis_method_core.terminate()
    if error < 0:
        raise OasisException("Error in terminate", error)


# oasis_abort instead of simply abort because there
# was a clash with another function name
def oasis_abort(component_id, routine, message, filename, line, error):
    """Aborts OASIS."""
    check_types([int, str, str, str, int, int],
                [component_id, routine, message, filename, line, error])
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
        """Returns the partition identifier."""
        return self.partition_id


class SerialPartition(Partition):
    """
    Serial partition
    
    :param int size: number of points in the partition
    :raises OasisException: if OASIS is unable to initialise the partition
    """
    def __init__(self, size):
        """Constructor"""
        check_types([int], [size])
        if size<=0:
            raise PyOasisException("Size must be <=0.")

        parameters = [0, 0, size]
        self.set(parameters)


class ApplePartition(Partition):
    """
    Apple partition
 
    :param int offset: offset according to the global index 
    :param int size: number of points in the partition  

    :raises OasisException: if OASIS is unable to initialise the partition
    """
    def __init__(self, offset, size):
        """Constructor"""
        check_types([int, int], [offset, size])
        if offset<0:
            raise PyOasisException("Offset <0.")
        if size<=0:
            raise PyOasisException("Size <=0.")

        parameters = [1, offset, size]
        self.set(parameters)


class BoxPartition(Partition):
    """
    Box partition
 
    :param int global_offset: offset according to the global index   
    :param int local_extent_x: extent in the x direction of the local \
                               partition
    :param int local_extent_y: extent in the y direction of the local \
                               partition 
    :param int global_extent_x: global extent in the x direction
    :raises OasisException: if OASIS is unable to initialise the partition
    """
    def __init__(self, global_offset, local_extent_x, local_extent_y,
                 global_extent_x):
        """Constructor"""
        check_types([int, int, int, int],
                    [global_offset, local_extent_x, local_extent_y,
                     global_extent_x])
        if global_offset<0:
            raise PyOasisException("Global offset <0.")

        if local_extent_x<=0:
            raise PyOasisException("Local extent in x-direction <=0.")

        if local_extent_y<=0:
            raise PyOasisException("Local extent in y-direction <=0.")
        if global_extent_x<=0:
            raise PyOasisException("Global extent in x-direction <=0.")


        parameters = [2, global_offset, local_extent_x, local_extent_y, 
                      global_extent_x]
        self.set(parameters)


class OrangePartition(Partition):
    """
    Orange partition
 
    :param offsets: list of offsets according to the global index  
    :type offsets: list of integers
    :param extents: list of the partition extents  
    :type extents: list of integers
    :raises OasisException: if OASIS is unable to initialise the partition
    """
    def __init__(self, offsets, extents):
        """Constructor"""
        check_types([list, list], [offsets, extents])
        n_offsets = len(offsets)
        if len(extents) != n_offsets:
            raise PyOasisException("Number of offsets != number of extents")
        for offset in offsets:
            if offset<0:
                raise PyOasisException("Offset <0.")
        for extent in extents:
            if extent<=0:
                raise PyOasisException("Extent <=0.")
        parameters = [3, n_offsets]
        for i in range(n_offsets):
            parameters.append(offsets[i])
            parameters.append(extents[i])
        self.set(parameters)


class PointsPartition(Partition):
    """
    Points partition
 
    :param global_indices: list containing the global indices of the \
                           points in the partition    
    :type global_indices: list of integers
    :raises OasisException: if OASIS is unable to initialise the partition
    """
    def __init__(self, global_indices):
        """Constructor"""
        check_types([list], [global_indices])
        if len(global_indices)==0:
            raise PyoasisException("Global indices list empty.")

        parameters = [4, len(global_indices)]
        for index in global_indices:
            parameters.append(index)
        self.set(parameters)


class Var:
    """
    Variable data

    :param string cdport: name
    :param int id_part: partition identifier
    :param id_var_nodims: rank and number of bundles
    :type id_var_nodims: list of 2 integers
    :param kinout: flag indicating whether the data is outgoing \
                   or ingoing
    :type kinout: pyoasis.OasisParameter
    :raises OasisException: if OASIS is unable to initialise \
                            the variable data 
    """
    def __init__(self, cdport, id_part, id_var_nodims, kinout):
        """Constructor"""
        check_types([str, int, list, int],
                    [cdport, id_part, id_var_nodims, kinout])
        if len(cdport) == 0:
            raise PyOasisException("Name empty.")
        if id_part<0:
            raise PyOasisException("Partition identifier <0.")
        if not (kinout == OasisParameters.OASIS_IN.value 
                or kinout == OasisParameters.OASIS_OUT.value):
            raise PyOasisException("kinout parameter neither OASIS_IN or OASIS_OUT.")
        self.name = cdport
        return_value = mod_oasis_var_core.def_var(id_part, self.name, id_var_nodims, 
                                                  kinout)
        error = return_value[1]
        if error < 0:
            raise OasisException("Error in def_var", error)
        self.var_id = return_value[0]

    def get_id(self):
        """
        :returns: the identifier of the variable data
        """
        return self.var_id
    
    def get_name(self):
        """
        :returns: name of variable data
        """
        return self.name

    def put(self, kstep, field):
        """
        Sends data to another model.

        :param int kstep: model time (in seconds)
        :param pyoasis.Array field: data
        """
        check_types([int, numpy.ndarray], [kstep, field])
        mod_oasis_getput_interface_core.put(self.var_id, kstep, field)

    def get(self, kstep, field):
        """
        Gets data from another model.

        :param int kstep: model time (in seconds)
        :param pyoasis.Array field: data
        """
        check_types([int, numpy.ndarray], [kstep, field])
        mod_oasis_getput_interface_core.get(self.var_id, kstep, field)
