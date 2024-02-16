#!/usr/bin/env python3

import math
import pyoasis
from pyoasis import OASIS
import numpy as np
import netCDF4
from mpi4py import MPI
from utils import *

try:
    import cartopy
    import cartopy.crs as ccrs
    import matplotlib.pyplot as plt
    import matplotlib.collections
    from matplotlib.colors import ListedColormap
    import os
    has_graphics = True
except ImportError:
    has_graphics = False


def caramelbleucm():
    if not has_graphics:
        return
    rcol = np.hstack((np.linspace(0.1, 0.0, 30 - 0 + 1)[:-1],
                      np.linspace(0.0, 0.8, 47 - 30 + 1)[:-1],
                      np.linspace(0.8, 1.0, 52 - 47 + 1)[:-1],
                      np.linspace(1.0, 1.0, 70 - 52 + 1)[:-1],
                      np.linspace(1.0, 1.0, 100 - 70 + 1)))
    gcol = np.hstack((np.linspace(0.1, 0.9, 30 - 0 + 1)[:-1],
                      np.linspace(0.9, 1.0, 47 - 30 + 1)[:-1],
                      np.linspace(1.0, 1.0, 52 - 47 + 1)[:-1],
                      np.linspace(1.0, 0.9, 70 - 52 + 1)[:-1],
                      np.linspace(0.9, 0.1, 100 - 70 + 1)))
    bcol = np.hstack((np.linspace(1.0, 1.0, 30 - 0 + 1)[:-1],
                      np.linspace(1.0, 1.0, 47 - 30 + 1)[:-1],
                      np.linspace(1.0, 0.8, 52 - 47 + 1)[:-1],
                      np.linspace(0.8, 0.0, 70 - 52 + 1)[:-1],
                      np.linspace(0.0, 0.1, 100 - 70 + 1)))
    alph = np.linspace(1.0, 1.0, 101)

    cm = np.array((np.transpose(rcol), np.transpose(gcol),
                  np.transpose(bcol), np.transpose(alph)))
    cm = np.transpose(cm)
    newmap = ListedColormap(cm, name='CaramelBleu')
    return newmap


comm = MPI.COMM_WORLD

has_graphics = comm.bcast(has_graphics, root=comm.rank)

dgrid = None
dgrid = comm.bcast(dgrid, root=0)
ll_plot = False
ll_plot = comm.bcast(ll_plot, root=0)

gf = netCDF4.Dataset('grids.nc', 'r')
lons = gf.variables[dgrid + '.lon'][:, :].flatten()
lats = gf.variables[dgrid + '.lat'][:, :].flatten()
n_points = lons.size
dgrid_corners = len(gf.dimensions['crn_' + dgrid])
dlon = gf.variables[dgrid + '.clo'][:].reshape(dgrid_corners, -1)
dlon = np.where(dlon > 180, dlon - 360, dlon)
dlat = gf.variables[dgrid + '.cla'][:].reshape(dgrid_corners, -1)
lonspan = np.abs(np.max(dlon, axis=0) - np.min(dlon, axis=0))
for i, span in enumerate(lonspan):
    if span > 180:
        if np.mean(dlon[:, i]) > 0.:
            dlon[:, i] = np.where(dlon[:, i] < 0, dlon[:, i] + 360, dlon[:, i])
        else:
            dlon[:, i] = np.where(dlon[:, i] > 0, dlon[:, i] - 360, dlon[:, i])
gf.close()

mf = netCDF4.Dataset('masks.nc', 'r')
msi = mf.variables[dgrid + '.msk'][:].flatten()
da_msk = msi == 1
mf.close()

da_lonlat = np.transpose(np.array([dlon, dlat]))
da_lonlat = np.delete(da_lonlat, np.where(da_msk), axis=0)

component_name = "receiver"
comp = pyoasis.Component(component_name, True, comm)

print(comp, flush=True)
print("n_points on destination side is {}".format(n_points), flush=True)

partition = pyoasis.SerialPartition(n_points)

scaled_var = pyoasis.Var("FRECVSCA", partition, OASIS.IN)
frac_var = pyoasis.Var("FRECVWGT", partition, OASIS.IN)
normalized_var = pyoasis.Var("FRECVNOR", partition, OASIS.IN)
comp.enddef()

date = int(0)

scaled = pyoasis.asarray(np.zeros((n_points)))
frac = pyoasis.asarray(np.zeros((n_points)))
normalized = pyoasis.asarray(np.zeros((n_points)))

scaled_var.get(date, scaled)
frac_var.get(date, frac)
normalized_var.get(date, normalized)

print('Receiver: shape of received field', scaled.shape)
scaled = np.delete(scaled, np.where(da_msk), axis=0)
frac = np.delete(frac, np.where(da_msk), axis=0)
fracnan = np.where(frac == 0.0, np.nan, frac)
normalized = np.delete(normalized, np.where(da_msk), axis=0)

dp_conv = math.pi / 180.

error = np.nanmean(np.abs((normalized - (scaled/fracnan))/normalized))
print("Average relative error is {}".format(error))
if error < 1.e-3:
    print("Data received successfully at time {}".format(date))

if not (has_graphics and ll_plot):
    exit()

cartopy.config['data_dir'] = os.path.join('.', 'cartopy')

ti_list = ["Scaled field without fracwgt","Normalized scaled field with fracwgt"]
for img in range(2):
    ti_str = "Test interpolation with PyOASIS\n"+ti_list[img]

    fig = plt.figure(img, figsize=(8.25, 11.75), frameon=True)
    plt.suptitle(ti_str)
    cmap = caramelbleucm()

    sd_proj = ccrs.PlateCarree()
    sd_lwdt = 0.0

    di_ax = plt.subplot(211, projection=sd_proj)
    di_ax.set_global()
    di_ax.coastlines(resolution='110m', linewidth=0.5)

    di_pc = matplotlib.collections.PolyCollection(da_lonlat)
    if img == 0:
        field = np.array(scaled)
    else:
        field = np.array(normalized)
    field = np.where(field == 0.0, np.nan, field)
    di_pc.set_array(field)
    di_pc.set_cmap(cmap)

    di_ax.add_collection(di_pc)
    di_gl = di_ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True,
                            linewidth=sd_lwdt, linestyle=':', color='gray')
    di_gl.top_labels = False
    di_gl.right_labels = False
    di_ax.set_title('Interpolated function on {} grid'.format(grid_longname(dgrid)))
    fig.colorbar(di_pc, ax=di_ax, shrink=.7)

    da_ax = plt.subplot(212, projection=sd_proj)
    da_ax.set_global()
    da_ax.coastlines(resolution='110m', linewidth=0.5)

    da_pc = matplotlib.collections.PolyCollection(da_lonlat)
    da_pc.set_array(np.array(fracnan))
    da_pc.set_cmap(cmap)

    da_ax.add_collection(da_pc)
    da_gl = da_ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True,
                            linewidth=sd_lwdt, linestyle=':', color='gray')
    da_gl.top_labels = False
    da_gl.right_labels = False
    da_ax.set_title('Active fraction on {} grid'.format(grid_longname(dgrid)))
    fig.colorbar(da_pc, ax=da_ax, shrink=.7)

    plt.subplots_adjust(left=0.10, right=1.00, wspace=0.05, hspace=0.)

plt.show()

del comp
