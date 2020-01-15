#!/usr/bin/python

import pyoasis

from mpi4py import MPI
import pyoasis

comm = MPI.COMM_WORLD

component_name = "model1"
print("Component name: " + component_name)

comp = pyoasis.Component(component_name, False, comm)

print("Component id: " + str( comp.id) )

local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))

coupl_comm = comp.create_couplcomm(1, comp.get_localcomm())
print("Coupling communicator: " + str(coupl_comm))

comp.enddef()

pyoasis.terminate()
