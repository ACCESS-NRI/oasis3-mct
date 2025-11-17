#!/usr/bin/env python3

import os
import math
import numpy as np
import pyoasis
from pyoasis import OASIS
import netCDF4
from mpi4py import MPI
from utils import *

comm = MPI.COMM_WORLD

has_graphics = None
has_graphics = comm.bcast(has_graphics, root=comm.size - 1)

sgrid = None
dgrid = None
ll_plot = None
if comm.rank == 0:
    sgrid = input('Enter the source grid code from {}:\n'.format(set(valid_grids)))
    if not grid_is_valid(sgrid):
        print('{} is not a valid grid'.format(sgrid), flush=True)
        comm.Abort()
    if grid_is_ocean(sgrid):
        dset = set(valid_grids) - set(ocean_grids)
    else:
        dset = set(valid_grids) - set((sgrid,))
    dgrid = input('Enter the target grid code from {}:\n'.format(dset))
    if not grid_is_valid(dgrid):
        print('{} is not a valid grid'.format(dgrid), flush=True)
        comm.Abort()
    if grid_is_ocean(sgrid) and grid_is_ocean(dgrid):
        print('Only one grid can be for ocean', flush=True)
        comm.Abort()
    if sgrid == 'torc' or dgrid == 'torc':
        os.symlink(os.path.join('..', '..', 'common_data', 'masks_torc_scrip.nc'),
                   'masks.nc')
    elif sgrid == 'nogt' or dgrid == 'nogt':
        os.symlink(os.path.join('..', '..', 'common_data', 'masks_nogt_scrip.nc'),
                   'masks.nc')
    else:
        os.symlink(os.path.join('..', '..', 'common_data', 'masks_no_atm.nc'), 'masks.nc')
    do_plot = input('Plot output [yes/no]\n')
    if (do_plot.lower() != 'yes' and do_plot.lower() != 'no'):
        print('{} is not a valid yes/no answer'.format(do_plot), flush=True)
        comm.Abort()
    else:
        ll_plot = do_plot.lower() == 'yes'

    write_namcouple(sgrid, dgrid, has_graphics)

dgrid = comm.bcast(dgrid, root=0)
ll_plot = comm.bcast(ll_plot, root=0)

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

scaled_var = pyoasis.Var("FSENDSCA", partition, OASIS.OUT)
frac_var = pyoasis.Var("FSENDWGT", partition, OASIS.OUT)
field_var = pyoasis.Var("FSENDNOR", partition, OASIS.OUT)
comp.enddef()

date = int(0)
frac = pyoasis.asarray(np.zeros((local_size), dtype=np.float64))
field = pyoasis.asarray(np.zeros((local_size), dtype=np.float64))

dp_conv = math.pi / 180.
field = 2.0 + np.sin(lats[offset:offset + local_size] * dp_conv) ** 3.0 * \
        np.cos(2.0 * lons[offset:offset + local_size] * dp_conv)
frac = 1.0 / (1.0 + np.exp(-0.2*(np.abs(lats[offset:offset + local_size]) - \
      60.0 + 10.0 * np.cos(8.0*lons[offset:offset + local_size] * dp_conv))))
frac = np.where(frac <= 1.e-1, 0.0, frac)
frac = np.where(frac >= 1.0-1.e-1, 1.0, frac)
scaled = pyoasis.asarray(frac * field)

if comm_rank == 0:
    print("Sent data: at time {}".format(date))

scaled_var.put(date, scaled)
frac_var.put(date, frac)
field_var.put(date, field, fracwgt=frac)

del comp
