#!/usr/bin/env python3

import os
import math
import numpy as np
import pyoasis
from pyoasis import OASIS
import netCDF4
from mpi4py import MPI

comm = MPI.COMM_WORLD

has_graphics = None
has_graphics = comm.bcast(has_graphics, root=comm.size - 1)

sgrid = 'nogt'
ll_plot = None
if comm.rank == 0:
    do_plot = input('Plot output [yes/no]\n')
    if (do_plot.lower() != 'yes' and do_plot.lower() != 'no'):
        print('{} is not a valid yes/no answer'.format(do_plot), flush=True)
        comm.Abort()
    else:
        ll_plot = do_plot.lower() == 'yes'

ll_plot = comm.bcast(ll_plot, root=0)

component_name = "sender-cube"
comp = pyoasis.Component(component_name, True, comm)

if comm.rank == 0:
    print(comp, flush=True)

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

sgrid = comp.localcomm.bcast(sgrid, root=0)

gf = netCDF4.Dataset('grids.nc', 'r')
lons = gf.variables[sgrid + '.lon'][:, :].data.T
lats = gf.variables[sgrid + '.lat'][:, :].data.T

nx_global = gf.dimensions['x_'+sgrid].size
ny_global = gf.dimensions['y_'+sgrid].size
nz_global = 3
n_points_2d = nx_global * ny_global
n_points_3d = n_points_2d * nz_global
gf.close()

if comm_rank == 0:
    print(comp)
    print("n_points per level on source side is {}".format(n_points_2d))
    print("n_levs on source side is {}".format(nz_global))

xdec = math.ceil(math.sqrt(comm_size))
while xdec <= comm_size:
    if comm_size % xdec == 0:
        break
ydec = int(comm_size/xdec)
nx = int(nx_global / xdec)
ny = int(ny_global / ydec)
idx = nx * (comm_rank % xdec)
idy = ny * math.floor(float(comm_rank)/float(xdec))
if idx + nx > nx_global:
    nx = nx_global - idx
if idy + ny > ny_global:
    ny = ny_global - idy
offset = nx_global * idy + idx

partitionb = pyoasis.BoxPartition(offset, nx, ny, nx_global, global_size=n_points_2d)
partitionc = pyoasis.CubePartition(offset, nx, ny, nx_global, ny_global, nz_global,
                                   global_size=n_points_3d)

fsendlv1_var = pyoasis.Var("FSENDLV1", partitionb, OASIS.OUT)
fsendlv2_var = pyoasis.Var("FSENDLV2", partitionb, OASIS.OUT)
fsendlv3_var = pyoasis.Var("FSENDLV3", partitionb, OASIS.OUT)
fsendf3d_var = pyoasis.Var("FSENDF3D", partitionc, OASIS.OUT)
comp.enddef()

local_size = nx * ny
date = int(0)
field = pyoasis.asarray(np.zeros((nx,ny,nz_global), dtype=np.float64))

dp_conv = math.pi / 180.
field[:,:,0] = 2.0 + np.sin(4.0 * lats[idx:idx+nx,idy:idy+ny] * dp_conv) ** 4.0 * \
               np.cos(8.0 * lons[idx:idx+nx,idy:idy+ny] * dp_conv)

field[:,:,1] = 2.0 + np.sin(2.0 * lats[idx:idx+nx,idy:idy+ny] * dp_conv) ** 4.0 * \
               np.cos(4.0 * lons[idx:idx+nx,idy:idy+ny] * dp_conv)

field[:,:,2] = 2.0 - np.cos(math.pi *
                            (np.arccos(np.cos(lons[idx:idx+nx,idy:idy+ny] * dp_conv) *
                                       np.cos(lats[idx:idx+nx,idy:idy+ny] * dp_conv)) /
                             (1.2 * math.pi)))

if comm_rank == 0:
    print("Sent data: at time {}".format(date))

fsendlv1_var.put(date, field[:,:,0])
fsendlv2_var.put(date, field[:,:,1])
fsendlv3_var.put(date, field[:,:,2])
fsendf3d_var.put(date, field)

del comp
