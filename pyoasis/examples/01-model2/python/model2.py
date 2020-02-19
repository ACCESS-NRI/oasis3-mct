#!/usr/bin/python3

import pyoasis

from mpi4py import MPI


comm = MPI.COMM_WORLD

component_name = "model2"
print("Component name: " + component_name)

comp = pyoasis.Component(component_name, comm)

print("Component id: " + str( comp.id ))

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(1, local_comm)
print("Coupling communicator: " + str(coupl_comm))

partition=pyoasis.SerialPartition(10, "partition")
print("Partition id: " + str(partition.id))
comp.enddef()

variable=pyoasis.Var(partition.id, "FSENDOCN", 1, 1, pyoasis.params.OASIS_OUT.value, pyoasis.params.OASIS_REAL.value)
print("Variable id: " + str(variable.id))

pyoasis.terminate()
