#!/usr/bin/python3

import pyoasis
import numpy

from mpi4py import MPI


comm = MPI.COMM_WORLD

component_name = "receiver"

comp = pyoasis.Component(component_name, True, comm)
print(comp)

n_points = 16

partition = pyoasis.SerialPartition(n_points)
print(partition)

variable = pyoasis.Var("FRECVATM", partition,
                       pyoasis.OasisParameters.OASIS_IN)
print(variable)

comp.enddef()

date = int(0)
field = pyoasis.asarray(numpy.zeros(n_points))

variable.get(date, field)

expected_field = pyoasis.asarray(range(n_points))
epsilon = 1e-8
error = abs((field-expected_field).sum())
if error < epsilon:
    print("Data received successfully")

comp.terminate()
