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


import pyoasis.exception

import pyoasis.mod_oasis_method
import pyoasis.mod_oasis_auxiliary_routines
import pyoasis.mod_oasis_sys
import pyoasis.mod_oasis_part
import pyoasis.mod_oasis_var
import pyoasis.mod_oasis_getput_interface

# oasis_abort instead of simply abort because there
# was a clash with another function name
def oasis_abort(component_id, routine, message, filename, line, error):
    """Aborts OASIS."""
    check_types([int, str, str, str, int, int],
                [component_id, routine, message, filename, line, error])
    mod_oasis_sys.oasis_abort(component_id, routine, message, filename,
                                   line, error)

def pyoasis_abort(exception):
    """
    Terminates cleanly the execution of OASIS and pyOASIS
    while dsiplaying an error message and the context  in which 
    the exception was raised.

    :param Exception exception: exception to be handled
    :raises PyOasisException: if an incorrect parameter is supplied
    """
    check_types([Exception], [exception])
    print(traceback.format_exc())
    pyoasis.mod_oasis_sys.oasis_abort(0, "", str(exception), "", 0, 0)

