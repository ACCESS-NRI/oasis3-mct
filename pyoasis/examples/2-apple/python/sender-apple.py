#!/usr/bin/python3

import numpy
import pyoasis

from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "sender-apple"

comp = pyoasis.Component(component_name, True, comm)
print(comp)

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(local_comm)
print("Coupling communicator: " + str(coupl_comm))

comm_rank = comp.get_localcomm_rank()
comm_size = comp.get_localcomm_size()

n_points = 16

local_size = int(n_points/comm_size)
offset = comm_rank*local_size

partition = pyoasis.ApplePartition(offset, local_size)
print(partition)

variable = pyoasis.Var("FSENDOCN", partition, 1,
                       pyoasis.OasisParameters.OASIS_OUT)
print(variable)

comp.enddef()

date = int(0)

field = pyoasis.Array(numpy.zeros(local_size))

for i in range(local_size):
    field[i] = offset + i

print("Sent data: "+str(field))

variable.put(date, field)

pyoasis.terminate()
