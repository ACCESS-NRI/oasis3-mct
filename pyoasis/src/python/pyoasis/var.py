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
import traceback


import pyoasis.mod_oasis_method
import pyoasis.mod_oasis_auxiliary_routines
import pyoasis.mod_oasis_sys
import pyoasis.mod_oasis_part
import pyoasis.mod_oasis_var
import pyoasis.mod_oasis_getput_interface


class Var:
    """
    Variable data

    :param string cdport: name
    :param int id_part: partition identifier
    :param int n_dimensions: number of dimensions
    :param kinout: flag indicating whether the data is outgoing \
                   or ingoing
    :type kinout: pyoasis.OasisParameter
    :raises OasisException: if OASIS is unable to initialise \
                            the variable data 
    :raises PyOasisException: if an incorrect parameter is supplied
    """
    def __init__(self, cdport, partition, n_dimensions, kinout):
        """Constructor"""
        
        pyoasis.check_types([str, pyoasis.Partition, int, pyoasis.OasisParameters],
                    [cdport, partition, n_dimensions, kinout])
        if len(cdport) == 0:
            raise pyoasis.PyOasisException("Name empty.")
        id_part = partition.get_id()
        if id_part < 0:
            raise pyoasis.PyOasisException("Partition identifier <0.")
        if n_dimensions < 0:
            raise pyoasis.PyOasisException("Number of dimensions <0.")
        if not (kinout == pyoasis.OasisParameters.OASIS_IN 
                or kinout == pyoasis.OasisParameters.OASIS_OUT):
            raise pyoasis.PyOasisException("kinout parameter neither OASIS_IN or OASIS_OUT.")
        self.name = cdport
        id_var_nodims = [n_dimensions, 1]
        return_value = pyoasis.mod_oasis_var.def_var(id_part, self.name, id_var_nodims, 
                                                  kinout.value)
        error = return_value[1]
        if error < 0:
            raise pyoasis.OasisException("Error in def_var", error)
        self.var_id = return_value[0]

    def get_id(self):
        """
        :returns: the identifier of the variable data
        :rtype: int
        """
        return self.var_id
    
    def get_name(self):
        """
        :returns: name of variable data
        :rtype: string
        """
        return self.name

    def put(self, kstep, field):
        """
        Sends data to another model.

        :param int kstep: model time (in seconds)
        :param pyoasis.Array field: data

        :raises OasisException: if OASIS is unable to send \
         data to the other component
        :raises PyOasisException: if an incorrect parameter is supplied 
        """
        pyoasis.check_types([int, numpy.ndarray], [kstep, field])
        error = pyoasis.mod_oasis_getput_interface.put(self.var_id, kstep, field)
        if (error < 0):
          raise pyoasis.OasisException("Error in sending data to another component", error)

    def get(self, kstep, field):
        """
        Gets data from another model.

        :param int kstep: model time (in seconds)
        :param pyoasis.Array field: data

        :raises OasisException: if OASIS is unable to receive \
        data from the other component
        :raises PyOasisException: if an incorrect parameter is supplied
        """
        pyoasis.check_types([int, numpy.ndarray], [kstep, field])
        error = pyoasis.mod_oasis_getput_interface.get(self.var_id, kstep, field)
        if (error < 0):
          raise pyoasis.OasisException("Error in getting data from another component", error)

    def __str__(self):
        return "Variable data: name: " + self.name + ", id: " + str(self.var_id)

