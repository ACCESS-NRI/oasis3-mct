#!/usr/bin/python3

import pyoasis

from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "sender-serial"

comp = pyoasis.Component(component_name, True, comm)
print(comp)

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(local_comm)
print("Coupling communicator: " + str(coupl_comm))

n_points = 16

partition = pyoasis.SerialPartition(n_points)
print(partition)

variable = pyoasis.Var("FSENDOCN", partition, 1,
                       pyoasis.OasisParameters.OASIS_OUT)
print(variable)

comp.enddef()

date = int(0)

field = pyoasis.Array(range(n_points))

variable.put(date, field)

pyoasis.terminate()
