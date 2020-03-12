#!/usr/bin/python3

import pyoasis
import numpy

from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "sender-orange"
print("Component name: " + component_name)

comp = pyoasis.Component(component_name, True, comm)

print("Component id: " + str(comp.get_id()))

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(1, local_comm)
print("Coupling communicator: " + str(coupl_comm))

comm_rank = comp.get_localcomm_rank()
comm_size = comp.get_localcomm_size()

n_points = 16
extent = int(n_points/comm_size)
offset = comm_rank*extent

offsets = [offset]
extents = [extent]

partition = pyoasis.OrangePartition(offsets, extents)
print("Partition id: " + str(partition.get_id()))

variable = pyoasis.Var(partition.get_id(), "FSENDOCN", 1, 1,
                       pyoasis.OasisParameters.OASIS_OUT.value)
print("Variable id: " + str(variable.get_id()))

comp.enddef()

date = int(0)

field = pyoasis.FloatArray(numpy.zeros(extent))
for i in range(extent):
    field[i] = offset + i

variable.put(date, field)

pyoasis.terminate()
