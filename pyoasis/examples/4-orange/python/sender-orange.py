#!/usr/bin/python3

import pyoasis
import numpy

from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "sender-orange"

comp = pyoasis.Component(component_name, True, comm)

print(comp)

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

n_points = 16
extent = int(n_points/comm_size)
offset = comm_rank*extent

offsets = [offset]
extents = [extent]

partition = pyoasis.OrangePartition(offsets, extents)
print(partition)

variable = pyoasis.Var("FSENDOCN", partition, 1,
                       pyoasis.OasisParameters.OASIS_OUT)
print(variable)

comp.enddef()

date = int(0)

field = pyoasis.Array(numpy.zeros(extent))
for i in range(extent):
    field[i] = offset + i

variable.put(date, field)

pyoasis.terminate()
