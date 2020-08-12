#!/usr/bin/python3

import pyoasis
import numpy

from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "sender-orange"

comp = pyoasis.Component(component_name, True, comm)

print(comp)

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(local_comm)
print("Coupling communicator: " + str(coupl_comm))

comm_rank = comp.get_localcomm_rank()
comm_size = comp.get_localcomm_size()

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
