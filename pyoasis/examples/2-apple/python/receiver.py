#!/usr/bin/python3

import pyoasis
import numpy

from mpi4py import MPI


comm = MPI.COMM_WORLD

component_name = "receiver"

comp = pyoasis.Component(component_name, True, comm)
print(comp)

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(local_comm)
print("Coupling communicator: " + str(coupl_comm))

n_points = 159999996#160000000

partition = pyoasis.SerialPartition(n_points)
print(partition)

variable = pyoasis.Var("FRECVATM", partition, 1,
                       pyoasis.OasisParameters.OASIS_IN)
print("Variable id: " + str(variable.get_id()))

comp.enddef()

date = int(0)
field = pyoasis.Array(numpy.zeros(n_points))

variable.get(date, field)

expected_field = pyoasis.Array(numpy.arange(n_points,dtype=numpy.float64))
epsilon = 1e-8
error = abs((field-expected_field).sum())
if(error < epsilon):
    print("Data received successfully")

pyoasis.terminate()
