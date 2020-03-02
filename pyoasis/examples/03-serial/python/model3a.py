#!/usr/bin/python3

import pyoasis

from mpi4py import MPI


comm = MPI.COMM_WORLD

component_name = "model3a"
print("Component name: " + component_name)

comp = pyoasis.Component(component_name, True, comm)

print("Component id: " + str( comp.id ))

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(1, local_comm)
print("Coupling communicator: " + str(coupl_comm))

partition=pyoasis.SerialPartition(3)
print("Partition id: " + str(partition.id))

variable=pyoasis.Var(partition.id, "FSENDOCN", 1, 1, pyoasis.params.OASIS_OUT.value, pyoasis.params.OASIS_REAL.value)
print("Variable id: " + str(variable.id))

comp.enddef()

date=int(0);
field=pyoasis.Array([1,2,3])
print("Sent data: "+str(field))

variable.put(date, field); 

pyoasis.terminate()
