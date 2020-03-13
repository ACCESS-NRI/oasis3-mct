#!/usr/bin/python3

import pyoasis
import numpy

from mpi4py import MPI


comm = MPI.COMM_WORLD

component_name = "receiver"
print("Component name: " + component_name)

comp = pyoasis.Component(component_name, True, comm)
print("Component id: " + str(comp.get_id()))

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(1, local_comm)
print("Coupling communicator: " + str(coupl_comm))

n_points = 16

partition = pyoasis.SerialPartition(n_points)
print("Partition id: " + str(partition.get_id()))

variable = pyoasis.Var("FRECVATM", partition.get_id(), [1, 1,],
                       pyoasis.OasisParameters.OASIS_IN.value)
print("Variable id: " + str(variable.get_id()))

comp.enddef()

date = int(0)
field = pyoasis.Array(numpy.zeros(n_points))

variable.get(date, field)

expected_field = pyoasis.Array(range(n_points))
epsilon = 1e-8
error = abs((field-expected_field).sum())
if(error < epsilon):
    print("Data received successfully")

pyoasis.terminate()
