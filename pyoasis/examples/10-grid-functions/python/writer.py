#!/usr/bin/env python3

import pyoasis
from pyoasis import OASIS
import numpy as np
import math

comp = pyoasis.Component("writer")

print(comp)

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

nx_loc = 18
ny_loc = 18
nx_global = comm_size*nx_loc
ny_global = ny_loc

partition = pyoasis.BoxPartition(comm_rank*nx_loc, nx_loc, ny_loc, nx_global)

dx = 360.0/nx_global
dy = 180.0/ny_global

lon = np.array([comm_rank*nx_loc*dx + float(i)*dx + dx/2.0 for i in range(nx_loc)],
               dtype=np.float64)
lon = np.tile(lon,(ny_loc,1)).T

lat = np.array([float(j)*dy + dy/2.0 for j in range(ny_loc)],
               dtype=np.float64)
lat = np.tile(lat,(nx_loc,1))

grid = pyoasis.Grid('pyoa', nx_global, ny_global, lon, lat, partition)

ncrn = 4
clo = pyoasis.asarray(np.zeros((nx_loc,ny_loc,ncrn),dtype=np.float64))
clo[:,:,0] = lon[:,:]  - dx/2.0
clo[:,:,1] = lon[:,:]  + dx/2.0
clo[:,:,2] = clo[:,:,1]
clo[:,:,3] = clo[:,:,0]
cla = pyoasis.asarray(np.zeros((nx_loc,ny_loc,ncrn),dtype=np.float64))
cla[:,:,0] = lat[:,:]  - dy/2.0
cla[:,:,1] = cla[:,:,0]
cla[:,:,2] = lat[:,:]  + dy/2.0
cla[:,:,3] = cla[:,:,2]

grid.set_corners(clo,cla)

msk = np.zeros((nx_loc,ny_loc), dtype=np.int32)
if comm_rank == 0:
    msk[4:6,2:16] = 1
    msk[6:11,(8,9,14,15)] = 1
    msk[11,(8,9,10,13,14,15)] = 1
    msk[12,9:15] = 1
    msk[13,10:14] = 1
elif comm_rank == 1:
    msk[(3,14),14:16] = 1
    msk[(4,13),12:16] = 1
    msk[(5,12),11:15] = 1
    msk[(6,11),10:13] = 1
    msk[(7,10), 9:12] = 1
    msk[8:10,2:11] = 1
elif comm_rank == 2:
    msk[(4,13),4:14] = 1
    msk[(5,12),3:15] = 1
    msk[(6,11),2:5] = 1
    msk[(6,11),13:16] = 1
    msk[7:11,2:4] = 1
    msk[7:11,14:16] = 1

grid.set_mask(msk)

frc = np.ones((nx_loc,ny_loc), dtype=np.float64)
frc = np.where(msk==1, 0.0, 1.0)

grid.set_frac(frc)

area = np.zeros((nx_loc,ny_loc), dtype=np.float64)
area[:,:] = (math.pi/180) * np.abs(np.sin(cla[:,:,2])-np.sin(cla[:,:,0])) * \
            np.abs(clo[:,:,1]-clo[:,:,0])

grid.set_area(area)

grid.write()

comp.enddef()

