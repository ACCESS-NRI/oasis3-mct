#!/usr/bin/python3

import pyoasis

from mpi4py import MPI


comm = MPI.COMM_WORLD

component_name = "sender-points"

comp = pyoasis.Component(component_name, True, comm)

print(comp)

n_points = 16

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

local_size = int(n_points/comm_size)
offset = comm_rank*local_size

indices = []
for i in range(local_size):
    indices.append(offset + i)

partition = pyoasis.PointsPartition(indices)
print(partition)

variable = pyoasis.Var("FSENDOCN", partition,
                       pyoasis.OasisParameters.OASIS_OUT)
print(variable)

comp.enddef()

date = int(0)

field = pyoasis.Array(indices)

variable.put(date, field)

pyoasis.terminate()
