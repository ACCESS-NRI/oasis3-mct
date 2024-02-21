#!/usr/bin/env python3

import math
import pyoasis
from pyoasis import OASIS
import numpy as np
import netCDF4
from mpi4py import MPI

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

dgrid = 'torc'
ll_plot = False
ll_plot = comm.bcast(ll_plot, root=0)

gf = netCDF4.Dataset('grids.nc', 'r')
lons = gf.variables[dgrid + '.lon'][:, :].flatten()
lats = gf.variables[dgrid + '.lat'][:, :].flatten()
n_levs = 3
n_points = lons.size
n_points_3d = n_points * n_levs
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
msi = mf.variables['torc.msk'][:].flatten()
da_msk_l1 = msi == 1
msi = mf.variables['tol2.msk'][:].flatten()
da_msk_l2 = msi == 1
msi = mf.variables['tol3.msk'][:].flatten()
da_msk_l3 = msi == 1
mf.close()

da_lonlat = np.transpose(np.array([dlon, dlat]))

component_name = "receiver"
comp = pyoasis.Component(component_name, True, comm)

print(comp, flush=True)
print("n_points per level on destination side is {}".format(n_points), flush=True)

partition = pyoasis.SerialPartition(n_points)
partition_3d = pyoasis.SerialPartition(n_points_3d)

vrecvan1 = pyoasis.Var("FRECVANA", partition, OASIS.IN)
vrecvan2 = pyoasis.Var("FRECVAN2", partition, OASIS.IN)
vrecvan3 = pyoasis.Var("FRECVAN3", partition, OASIS.IN)
vrecva3d = pyoasis.Var("FRECVA3D", partition_3d, OASIS.IN)
comp.enddef()

date = int(0)

frecvan1 = pyoasis.asarray(np.zeros((n_points)))
frecvan2 = pyoasis.asarray(np.zeros((n_points)))
frecvan3 = pyoasis.asarray(np.zeros((n_points)))
frecva3d = pyoasis.asarray(np.zeros((n_points, n_levs)))

vrecvan1.get(date,frecvan1)
vrecvan2.get(date,frecvan2)
vrecvan3.get(date,frecvan3)
vrecva3d.get(date,frecva3d)

print('Receiver: shape of received 2d field', frecvan1.shape)
print('Receiver: shape of received 3d field', frecva3d.shape)

error = np.nanmean(np.abs(np.where(da_msk_l1, np.nan, frecvan1) - frecva3d[:,0]))
error = max(error, np.nanmean(np.abs(np.where(da_msk_l2, np.nan, frecvan2) - frecva3d[:,1])))
error = max(error, np.nanmean(np.abs(np.where(da_msk_l3, np.nan, frecvan3) - frecva3d[:,2])))

print("Average relative error is {}".format(error))
if error < 1.e-3:
    print("Data received successfully at time {}".format(date))

if not (has_graphics and ll_plot):
    exit()

cartopy.config['data_dir'] = os.path.join('.', 'cartopy')

ti_list = ["Three 2D fields","A single 3D field"]
for img in range(2):
    ti_str = "Test interpolation with PyOASIS\n"+ti_list[img]

    fig = plt.figure(img, figsize=(8.25, 11.75), frameon=True)
    plt.suptitle(ti_str)
    cmap = caramelbleucm()

    sd_proj = ccrs.PlateCarree()
    sd_lwdt = 0.0

    di_ax = plt.subplot(311, projection=sd_proj)
    di_ax.set_global()
    di_ax.coastlines(resolution='110m', linewidth=0.5)

    di_pc = matplotlib.collections.PolyCollection(da_lonlat)
    if img == 0:
        field = frecvan1
    else:
        field = frecva3d[:,0]
    field = np.where(field == 0.0, np.nan, field)
    di_pc.set_array(field)
    di_pc.set_cmap(cmap)

    di_ax.add_collection(di_pc)
    di_gl = di_ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True,
                            linewidth=sd_lwdt, linestyle=':', color='gray')
    di_gl.top_labels = False
    di_gl.right_labels = False
    di_ax.set_title('Interpolated function at surface')
    fig.colorbar(di_pc, ax=di_ax, shrink=.7)

    da_ax = plt.subplot(312, projection=sd_proj)
    da_ax.set_global()
    da_ax.coastlines(resolution='110m', linewidth=0.5)

    da_pc = matplotlib.collections.PolyCollection(da_lonlat)
    if img == 0:
        field = frecvan2
    else:
        field = frecva3d[:,1]
    field = np.where(field == 0.0, np.nan, field)
    da_pc.set_array(np.array(field))
    da_pc.set_cmap(cmap)

    da_ax.add_collection(da_pc)
    da_gl = da_ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True,
                            linewidth=sd_lwdt, linestyle=':', color='gray')
    da_gl.top_labels = False
    da_gl.right_labels = False
    da_ax.set_title('Interpolated function at depth 1000 mt')
    fig.colorbar(da_pc, ax=da_ax, shrink=.7)

    db_ax = plt.subplot(313, projection=sd_proj)
    db_ax.set_global()
    db_ax.coastlines(resolution='110m', linewidth=0.5)

    db_pc = matplotlib.collections.PolyCollection(da_lonlat)
    if img == 0:
        field = frecvan3
    else:
        field = frecva3d[:,2]
    field = np.where(field == 0.0, np.nan, field)
    db_pc.set_array(np.array(field))
    db_pc.set_cmap(cmap)

    db_ax.add_collection(db_pc)
    db_gl = db_ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True,
                            linewidth=sd_lwdt, linestyle=':', color='gray')
    db_gl.top_labels = False
    db_gl.right_labels = False
    db_ax.set_title('Interpolated function at depth 3500 mt')
    fig.colorbar(db_pc, ax=db_ax, shrink=.7)

    plt.subplots_adjust(left=0.10, right=1.00, wspace=0.05, hspace=0.25)

plt.show()

del comp
