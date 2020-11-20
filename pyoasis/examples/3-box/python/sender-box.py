#!/usr/bin/env python3

import pyoasis
from pyoasis import OASIS
from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "sender-box"

comp = pyoasis.Component(component_name, True, comm)

print(comp)

rank = comp.localcomm.rank

global_offsets = [0, 2, 8, 10]
partition = pyoasis.BoxPartition(global_offsets[rank], 2, 2, 4)
print(partition)

variable = pyoasis.Var("FSENDOCN", partition, OASIS.OUT)
print(variable)

comp.enddef()

intracomm = comp.get_intracomm("receiver")
intercomm = comp.get_intercomm("receiver")

print("Sender intra_comm: rank = {} of {}".format(intracomm.rank,
                                                  intracomm.size))
print("Sender inter_comm: rank = {} of {} Remote size = {}".format(intercomm.rank,
                                                                   intercomm.size,
                                                                   intercomm.remote_size))

date = int(0)
data = [[0, 1, 4, 5], [2, 3, 6, 7],
        [8, 9, 12, 13], [10, 11, 14, 15]]
field = pyoasis.asarray(data[rank])

print(variable.put(date, field))

if rank % 2 == 0:
    del comp
