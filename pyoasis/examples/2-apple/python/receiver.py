#!/usr/bin/python3

import numpy
import pyoasis
from pyoasis import OasisParameters as OPar

from mpi4py import MPI

component_name = "receiver"

comp = pyoasis.Component(component_name)
print(comp)

n_points = 1600

partition = pyoasis.SerialPartition(n_points)
print(partition)

variable = pyoasis.Var("FRECVATM", partition, OPar.OASIS_IN)
print("Variable id: " + str(variable.get_id()))

comp.enddef()

date = int(0)
field = pyoasis.asarray(numpy.zeros(n_points))

variable.get(date, field)

expected_field = pyoasis.asarray(numpy.arange(n_points, dtype=numpy.float64))
epsilon = 1e-8
error = abs((field - expected_field).sum())
if error < epsilon:
    print("Data received successfully")

pyoasis.terminate()
