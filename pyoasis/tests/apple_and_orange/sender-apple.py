#!/usr/bin/python3

import numpy
import pyoasis

from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "sender-apple"

try:
    comp = pyoasis.Component(component_name, True, comm)
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

n_points = 16

local_size = int(n_points / comm_size)
offset = comm_rank * local_size

try:
    partition = pyoasis.ApplePartition(offset, local_size)
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

try:
    variable = pyoasis.Var("FSENDOCN", partition,
                           pyoasis.OasisParameters.OASIS_OUT)
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

try:
    comp.enddef()
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

date = int(0)

try:
    field = pyoasis.Array(numpy.zeros(local_size))
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

for i in range(local_size):
    field[i] = offset + i

print("Sent data: " + str(field))

try:
    variable.put(date, field)
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

try:
    pyoasis.terminate()
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)
