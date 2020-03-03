#!/usr/bin/python3

import pyoasis

from mpi4py import MPI


comm = MPI.COMM_WORLD

component_name = "model3a"
print("Component name: " + component_name)

comp = pyoasis.Component(component_name, True, comm)

print("Component id: " + str(comp.get_id()))

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(1, local_comm)
print("Coupling communicator: " + str(coupl_comm))

rank = comp.get_localcomm_rank()
size = comp.get_localcomm_size()

global_offsets = [0, 2, 8, 10]
partition = pyoasis.BoxPartition(global_offsets[rank], 2, 2, 4)
print("Partition id: " + str(partition.id))

variable = pyoasis.Var(partition.id, "FSENDOCN", 1, 1,
                       pyoasis.params.OASIS_OUT.value,
                       pyoasis.params.OASIS_REAL.value)
print("Variable id: " + str(variable.id))

comp.enddef()

date = int(0)
data = [[0, 1, 4, 5], [2, 3, 6, 7],
        [8, 9, 12, 13], [10, 11, 14, 15]]
field = pyoasis.Array(data[rank])

variable.put(date, field)

pyoasis.terminate()
