#!/usr/bin/python3

import pyoasis
import numpy

from mpi4py import MPI

comm = MPI.COMM_WORLD

component_name = "sender-orange"

comp = pyoasis.Component(component_name, True, comm)

local_comm_rank = comp.localcomm.rank
local_comm_size = comp.localcomm.size

icpl = 1
if local_comm_size > 3:
    if local_comm_rank >= local_comm_size - 2:
        icpl = MPI.UNDEFINED

print(comp, flush = True)

comp.create_couplcomm(icpl)

if icpl == 1:
    comm_rank = comp.couplcomm.rank
    comm_size = comp.couplcomm.size

    n_points = 16
    extent = int(n_points/comm_size)
    offset = comm_rank*extent
    
    offsets = [offset]
    extents = [extent]
    
    partition = pyoasis.OrangePartition(offsets, extents)
    print(partition, flush=True)
    
    variable = pyoasis.Var("FSENDOCN", partition, 1,
                           pyoasis.OasisParameters.OASIS_OUT)
    print(variable, flush=True)
    
comp.enddef()
    
if icpl == 1:
    date = int(0)
    
    field = pyoasis.Array(numpy.zeros(extent))
    for i in range(extent):
        field[i] = offset + i
    
    variable.put(date, field)
    
pyoasis.terminate()
