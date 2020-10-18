#!/usr/bin/python3

import pyoasis
from mpi4py import MPI
import time
import numpy as np

stt = time.time()
comm = MPI.COMM_WORLD
print('Sender: Time for comm = {} s.'.format(time.time()-stt), flush=True)

component_name = "sender-serial"

stt = time.time()
comp = pyoasis.Component(component_name, True, comm)
print(comp)
print('Sender: Time for Component = {} s.'.format(time.time()-stt), flush=True)

stt = time.time()
local_comm = comp.get_localcomm()
print("Local communicator: " + str(local_comm))
print('Sender: Time for local comm = {} s.'.format(time.time()-stt), flush=True)

stt = time.time()
coupl_comm = comp.create_couplcomm(local_comm)
print("Coupling communicator: " + str(coupl_comm))
print('Sender: Time for global comm = {} s.'.format(time.time()-stt), flush=True)

n_points = 160000000

stt = time.time()
partition = pyoasis.SerialPartition(n_points)
print(partition)
print('Sender: Time for partition = {} s.'.format(time.time()-stt), flush=True)

stt = time.time()
variable = pyoasis.Var("FSENDOCN", partition, 1,
                       pyoasis.OasisParameters.OASIS_OUT)
print('Sender: Time for Var = {} s.'.format(time.time()-stt), flush=True)
print(variable)

comp.enddef()

date = int(0)

stt = time.time()
field = pyoasis.Array(np.arange(n_points,dtype=np.float64))
print('Sender: Time for Array = {} s.'.format(time.time()-stt), flush=True)

stt = time.time()
variable.put(date, field)
print('Sender: Time for Put = {} s.'.format(time.time()-stt), flush=True)

pyoasis.terminate()
