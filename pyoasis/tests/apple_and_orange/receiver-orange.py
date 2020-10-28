#!/usr/bin/python3

import pyoasis
import numpy
import sys

from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "receiver"

try:
    comp = pyoasis.Component(component_name, True, comm)
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

n_points = 16
extent = int(n_points / comm_size)
offset = comm_rank * extent

offsets = [offset]
extents = [extent]

try:
    partition = pyoasis.OrangePartition(offsets, extents)
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

try:
    variable = pyoasis.Var("FRECVATM", partition,
                           pyoasis.OasisParameters.OASIS_IN)
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

try:
    comp.enddef()
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

date = int(0)
field = pyoasis.Array(numpy.zeros(extent))

try:
    variable.get(date, field)
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

expected_field = pyoasis.Array(numpy.zeros(extent))
for i in range(extent):
    expected_field[i] = offset + i

try:
    pyoasis.terminate()
except (pyoasis.OasisException, pyoasis.OasisException) as exception:
    pyoasis.pyoasis_abort(exception)

epsilon = 1e-8
error = abs((field - expected_field).sum())
if error < epsilon:
    sys.exit(0)
else:
    sys.exit(-1)
