#!/usr/bin/python3

import pyoasis
import numpy

from mpi4py import MPI


comm = MPI.COMM_WORLD

component_name = "receiver"
print("Component name: " + component_name)

comp = pyoasis.Component(component_name, True, comm)
print("Component id: " + str(comp.get_id()))

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

n_points = 16
extent = int(n_points/comm_size)
offset = comm_rank*extent

print ("*** "+str(extent)+" "+str(offset))

offsets = [offset]
extents = [extent]

partition = pyoasis.OrangePartition(offsets, extents)
print("Partition id: " + str(partition.get_id()))

variable = pyoasis.Var("FRECVATM", partition, 1,
                       pyoasis.OasisParameters.OASIS_IN)
print("Variable id: " + str(variable.get_id()))

comp.enddef()

date = int(0)
field = pyoasis.Array(numpy.zeros(extent))

variable.get(date, field)

expected_field = pyoasis.Array(numpy.zeros(extent))
for i in range(extent):
    expected_field[i] = offset + i + 1

epsilon = 1e-8
error = abs((field-expected_field).sum())
if(error < epsilon):
    print("Data received successfully")

pyoasis.terminate()
