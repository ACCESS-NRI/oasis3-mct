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



def terminate():
    """
    Ends the coupling.

    :raises OasisException: if OASIS is unable to end the coupling
    """
    error = pyoasis.mod_oasis_method.terminate()
    if error < 0:
        raise pyoasis.OasisException("Error in terminate", error)
