#!/usr/bin/env python3

__doc__ = """This python script converts a grid from the OASIS-SCRIP file format to the ESMF-SCRIP file format.
This format is capable of storing either 2D logically rectangular grids or 2D unstructured grids.
The grid should be defined in 3 existing input files: grids.nc, masks.nc, areas.nc
The grid is written in 1 output file: [gridname]_ESMF_ScripFmt.nc

Input: grid name to be converted (first argument of this script)
Output: netcdf grid file in ESMF-SCRIP format
        netcdf grid file in ESMF unstructured format if the grid is unstructured
"""

__author__ = "Gabriel Jonville - July 2019 - Updated february 2021"

import os
import sys
import numpy as np
import netCDF4 as nc
import time
import subprocess

#print(str(sys.argv))
if len(sys.argv) == 3:
    grid = sys.argv[1]
    fgridoasis_path = sys.argv[2]
else:
    print("USAGE: python ./{} gridname gridpath".format(sys.argv[0]))
    sys.exit()

fgridoasis = 'grids.nc'

##### TESTER si grid est bien dans fgridoasis
#if grid not in gridnames:
#    print("STOP! Gridname should be in {}\n".format(gridnames))
#    sys.exit()


def grid_is_unstruct(gr):
    return gr in ("nogt", "t12e", "icos", "icoh", "bt42", "ssea", "sse7", "t127", "t359","t799")


fgridesmf_s=grid+'_ESMF_ScripFmt.nc'
print("--\nConvert grid {} from OASIS-SCRIP to ESMF-SCRIP format".format(grid))
print("Writting in {}\n--".format(fgridesmf_s))


### OASIS grid
# Open a netCDF file in read mode
frnc = nc.Dataset(os.path.join(fgridoasis_path,fgridoasis), 'r')
# Open a new netCDF file in write mode
fwnc = nc.Dataset(fgridesmf_s, 'w', format='NETCDF4_CLASSIC')
# Read netCDF dimension
x = len(frnc.dimensions['x_'+grid])
y = len(frnc.dimensions['y_'+grid])
crn = len(frnc.dimensions['crn_'+grid])
if y==1:
    rank=1
else:
    rank=2
# Read netCDF variable
lat = frnc.variables[grid+'.lat'][:,:]
lon = frnc.variables[grid+'.lon'][:,:]
cla = frnc.variables[grid+'.cla'][:,:,:]
clo = frnc.variables[grid+'.clo'][:,:,:]
# Close netCDF file
frnc.close()


### ESMF grid
# Create netCDF dimension
grid_size = len(fwnc.createDimension('grid_size',x*y))
grid_corners = len(fwnc.createDimension('grid_corners',crn))
grid_rank = len(fwnc.createDimension('grid_rank',rank))
# Create netCDF variable / Put data / Set attribute
grid_dims = fwnc.createVariable('grid_dims',np.int32,('grid_rank',))
if y==1:
    grid_dims[:] = (x,)
else:
    grid_dims[:] = (x,y) 

grid_center_lat = fwnc.createVariable('grid_center_lat',np.float64,('grid_size',))
grid_center_lat[:] = np.reshape(lat, grid_size, order='C')   # read/write the elements using C-like index order
grid_center_lat.units = 'degrees'

grid_center_lon = fwnc.createVariable('grid_center_lon',np.float64,('grid_size',))
grid_center_lon[:] = np.reshape(lon, grid_size, order='C')   # read/write the elements using C-like index order
grid_center_lon.units = 'degrees'

grid_corner_lat = fwnc.createVariable('grid_corner_lat',np.float64,('grid_size','grid_corners'))
grid_corner_lat[:,:] = np.reshape(cla.T,(grid_size, grid_corners), order='F')   # read/write the elements using Fortran-like index order
grid_corner_lat.units = 'degrees'

grid_corner_lon = fwnc.createVariable('grid_corner_lon',np.float64,('grid_size','grid_corners'))
grid_corner_lon[:,:] = np.reshape(clo.T,(grid_size, grid_corners), order='F')   # read/write the elements using Fortran-like index order
grid_corner_lon.units = 'degrees'


### OASIS mask
fgridoasis = 'masks.nc'
# Open a netCDF file in read mode
frnc = nc.Dataset(os.path.join(fgridoasis_path,fgridoasis), 'r')
# Read netCDF variable
msk = frnc.variables[grid+'.msk'][:,:]
# Close netCDF file
frnc.close()


### ESMF mask
# Create netCDF variable / Put data / Set attribute
grid_imask = fwnc.createVariable('grid_imask',np.int32,('grid_size',))
grid_imask[:] = np.reshape(msk, grid_size, order='C')
grid_imask[:] = np.invert(grid_imask)+2   # invert mask for ESMF format
grid_imask.masked_value = "0 (land)"
grid_imask.unmasked_value = "1 (sea)"


### OASIS areas
#SV fgridoasis = 'areas.nc'
# Open a netCDF file in read mode
#SV frnc = nc.Dataset(os.path.join(fgridoasis_path,fgridoasis), 'r')
# Read netCDF variable
#SV srf = frnc.variables[grid+'.srf'][:,:]
# Close netCDF file
#SV frnc.close()


### ESMF areas
# Create netCDF variable / Put data / Set attribute
#SV grid_area = fwnc.createVariable('grid_area',np.float64,('grid_size',))
#SV grid_area[:] = np.reshape(srf, grid_size, order='C')
#SV grid_area.units = 'm^2'


# Global netCDF attributes
fwnc.description = grid+' grid in ESMF-SCRIP format'
fwnc.history = 'Created '+time.ctime(time.time())
fwnc.source = 'netCDF4 python '+sys.argv[0]

## all of the Dimension instances in the Dataset are stored in a dictionary
#for dimname in fwnc.dimensions.keys() :
#    dim = fwnc.dimensions[dimname]
#    print(dimname, len(dim))
## all of the variables in the Dataset are stored in a dictionnary
#for varname in fwnc.variables.keys() :
#    var = fwnc.variables[varname]
#    print(varname, var.dtype, var.dimensions, var.shape)

# Write and close the netCDF file
fwnc.close()


fgridesmf = grid+'_ESMF.nc'
if os.path.exists(os.path.join('.',fgridesmf)):
    os.remove(os.path.join('.',fgridesmf))

if grid_is_unstruct(grid):
    fgridesmf_u = grid+'_ESMF_unstruct.nc'
    cmd = 'ESMF_Scrip2Unstruct {} {} 0'.format(fgridesmf_s,fgridesmf_u)
    #from python3.5#subprocess.run(cmd,shell=True)
    subprocess.call(cmd,shell=True)
    os.symlink(os.path.join('.',fgridesmf_u),os.path.join('.',fgridesmf))
    print("--")
else:
    os.symlink(os.path.join('.',fgridesmf_s),os.path.join('.',fgridesmf))

