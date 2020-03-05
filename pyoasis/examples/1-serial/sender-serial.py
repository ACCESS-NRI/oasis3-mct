#!/usr/bin/python3

import pyoasis

from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "sender-serial"
print("Component name: " + component_name)

comp = pyoasis.Component(component_name, True, comm)
print("Component id: " + str(comp.get_id()))

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(1, local_comm)
print("Coupling communicator: " + str(coupl_comm))

n_points = 16

partition = pyoasis.SerialPartition(n_points)
print("Partition id: " + str(partition.get_id()))

variable = pyoasis.Var(partition.get_id(), "FSENDOCN", 1, 1,
                       pyoasis.OasisParameters.OASIS_OUT.value,
                       pyoasis.OasisParameters.OASIS_REAL.value)
print("Variable id: " + str(variable.get_id()))

comp.enddef()

date = int(0)

field = pyoasis.FloatArray(range(n_points))

variable.put(date, field)

pyoasis.terminate()
