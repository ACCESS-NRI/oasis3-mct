#!/usr/bin/python3

import os
import math
import numpy as np
import pyoasis
import netCDF4
from mpi4py import MPI
from utils import *

comm = MPI.COMM_WORLD

has_graphics = None
has_graphics = comm.bcast(has_graphics, root=comm.size - 1)

sgrid = None
dgrid = None
if comm.rank == 0:
    sgrid = input('Enter the source grid code:\n')
    if not grid_is_valid(sgrid):
        print('{} is not a valid grid'.format(sgrid), flush=True)
        comm.Abort()
    dgrid = input('Enter the target grid code:\n')
    if not grid_is_valid(dgrid):
        print('{} is not a valid grid'.format(dgrid), flush=True)
        comm.Abort()
    if grid_is_ocean(sgrid) and grid_is_ocean(dgrid):
        print('Only one grid can be for ocean', flush=True)
        comm.Abort()
    if sgrid == 'torc' or dgrid == 'torc':
        os.symlink(os.path.join('..', 'data', 'masks_torc_scrip.nc'), 'masks.nc')
    elif sgrid == 'nogt' or dgrid == 'nogt':
        os.symlink(os.path.join('..', 'data', 'masks_nogt_scrip.nc'), 'masks.nc')
    else:
        os.symlink(os.path.join('..', 'data', 'masks_no_atm.nc'), 'masks.nc')
    write_namcouple(sgrid, dgrid, has_graphics)

dgrid = comm.bcast(dgrid, root=0)

component_name = "sender-apple"
comp = pyoasis.Component(component_name, True, comm)

if comm.rank == 0:
    print(comp, flush=True)

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

sgrid = comp.localcomm.bcast(sgrid, root=0)

gf = netCDF4.Dataset('grids.nc', 'r')
lons = gf.variables[sgrid + '.lon'][:, :].flatten()
lats = gf.variables[sgrid + '.lat'][:, :].flatten()
n_points = lons.size
gf.close()

if comm_rank == 0:
    print(comp)
    print("n_points on source side is {}".format(n_points))

local_size = int(n_points / comm_size)
offset = comm_rank * local_size
if comm_rank == comm_size - 1:
    local_size = n_points - offset

partition = pyoasis.ApplePartition(offset, local_size)

variable = pyoasis.Var("FSENDANA", partition,
                       pyoasis.OasisParameters.OASIS_OUT,
                       bundle_size=2)
comp.enddef()

date = int(0)
bundle = pyoasis.asarray(np.zeros((local_size, 2), dtype=np.float64))

dp_conv = math.pi / 180.
bundle[:, 0] = 2.0 + np.sin(2.0 * lats[offset:offset + local_size] * dp_conv) ** 4.0 * \
               np.cos(4.0 * lons[offset:offset + local_size] * dp_conv)

bundle[:, 1] = 2.0 - np.cos(math.pi *
                            (np.arccos(np.cos(lons[offset:offset + local_size] * dp_conv) *
                                       np.cos(lats[offset:offset + local_size] * dp_conv)) /
                             (1.2 * math.pi)))

if comm_rank == 0:
    print("Sent data: at time {}".format(date))

variable.put(date, bundle)

comp.terminate()
