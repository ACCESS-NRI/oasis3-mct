#!/usr/bin/python3

import pyoasis

from mpi4py import MPI


comm = MPI.COMM_WORLD

component_name = "sender-box"

comp = pyoasis.Component(component_name, True, comm)

print(comp)

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(local_comm)
print("Coupling communicator: " + str(coupl_comm))

rank = comp.get_localcomm_rank()

global_offsets = [0, 2, 8, 10]
partition = pyoasis.BoxPartition(global_offsets[rank], 2, 2, 4)
print(partition)

variable = pyoasis.Var("FSENDOCN", partition, 1,
                       pyoasis.OasisParameters.OASIS_OUT)
print(variable)

comp.enddef()

date = int(0)
data = [[0, 1, 4, 5], [2, 3, 6, 7],
        [8, 9, 12, 13], [10, 11, 14, 15]]
field = pyoasis.Array(data[rank])

variable.put(date, field)

pyoasis.terminate()
