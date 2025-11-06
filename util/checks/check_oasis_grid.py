#!/usr/bin/env python3
import numpy as np
import os
import netCDF4
import matplotlib.pyplot as plt
from shapely.geometry import Point, Polygon, LinearRing
from pyproj import Proj
import time
from copy import deepcopy

## Graphical utilities

def quiver_coords(ax, poly, col):
    pts = list(poly.exterior.coords)
    x, y = zip(*pts)
    x = np.array(x)
    y = np.array(y)
    ax.quiver(x[:-1], y[:-1], x[1:]-x[:-1], y[1:]-y[:-1], scale_units='xy', angles='xy', scale=1, color=col)

def plot_coords(ax, poly, col):
    pts = list(poly.exterior.coords)
    x, y = zip(*pts)
    ax.plot(x, y, c=col)

def plot_centres(ax, centre, col):
    pts = list(centre.coords)
    x, y = zip(*pts)
    ax.plot(x, y, col+'o')

## Shapely utilities

def duplicated_corners(r):
    dupl_crn = {}
    crn_list = list(r.coords)[:-1]
    crn_set = set(crn_list)
    if len(crn_set) < len(crn_list):
        for crn in crn_set:
            if crn_list.count(crn) > 1:
                dupl_crn[crn] = (crn_list.index(crn), crn_list.count(crn))
    return dupl_crn

def fit_range(lon):
    if lon > 180:
        return lon - 360.
    if lon <= -180:
        return lon + 360
    return lon

def duplicated_to_end(cells):
    r = LinearRing(cells)
    dupl_crn = duplicated_corners(r)
    if len(dupl_crn) > 1:
        raise ValueError("duplicated_to_end is meaningless for more than one duplicated corner")
    for pt in dupl_crn:
        for j in range(len(cells)-dupl_crn[pt][0]-dupl_crn[pt][1]):
            cells.insert(0,cells.pop(-1))
    return cells

#############################
# USER INPUT
#############################

stop_on_error = False # Stop on first not compliant cell (useful dor dealing with one error at a time)
first_cell =  0       # Restart cell (useful for dealing with one error at a time)
skip_mask = True      # Do not check masked cells
oasis_files = True    # Input from OASIS compliant files (naming conventions)

manual_input = False  # Use handwritten values for testing the script itself
terse_output = not manual_input and not stop_on_error  # Less output for overall analysis

gin = 'feom'
gmn = 'feom'
if oasis_files:
    GridFile = '/home/globc/andrea/WORK/JAN-BUG-OASIS/grids.nc'
    MasksFile = '/home/globc/andrea/WORK/JAN-BUG-OASIS/masks.nc'
else:
    GridFile = '/scratch/globc/andrea/COUPLING_VHR/GRIDS_01_SINGLE_NEWLAT/grids_nemo_crn.nc'
    MasksFile = '/scratch/globc/andrea/COUPLING_VHR/GRIDS_01_SINGLE_NEWLAT/masks_nemo.nc'

pdict = {True:{'action':'Analysis of ',
               'dgen':{True:'It is not degenerate.',False:'It is degenerate.'},
               'dcvx':{True:'It is convex.',False:'It is not convex.'},
               'dccw':{True:'It is counterclocwise.',False:'It is not counterclockwise.'},
               'dctr':{True:'It contains its centre.',False:'It does not contain its centre.'},
               'ddup':{True:'It has at most 1 dup crn.',False:'It has more than 1 duplicated corner.'}},
         False:{'action':'Problem on ',
                'dgen':{True:'',False:'It is degenerate.'},
                'dcvx':{True:'',False:'It is not convex.'},
                'dccw':{True:'',False:'It is not counterclockwise.'},
                'dctr':{True:'',False:'It does not contain its centre.'},
                'ddup':{True:'',False:'It has more than 1 duplicated corner.'}}}

if not manual_input:
    print("Coherency analysis of grid {} from file {}".format(gin,GridFile))
    print("---------------------------------\n")

cells_coord=[]
centres_coord=[]

if manual_input:
    # Regular cell
    cells_coord.append([[10,10], [50,8], [52,38], [12,40]])
    centres_coord.append([27,21])
    # Self crossing cell
    cells_coord.append([[10,50], [50,48], [12,80], [52,78]])
    centres_coord.append([27,53])
    # Clockwise cell
    cells_coord.append([[72,40], [112,38], [110,8], [70,10]])
    centres_coord.append([87,21])
    # Cell not containing its centre
    cells_coord.append([[70,50], [110,48], [112,78], [72,80]])
    centres_coord.append([70,76])
    # Degenerated (one line) cell
    cells_coord.append([[40,-5], [80,5], [80,5], [40,-5]])
    centres_coord.append([60,0])
    # Regular 8 sides cell
    cells_coord.append([[140,0],[160,0],[180,10],[180,20],[160,30],[140,30],[120,20],[120,10]])
    centres_coord.append([150,15])
    # Self crossing 8 sides cell
    cells_coord.append([[140,35],[160,35],[180,45],[180,55],[140,65],[160,65],[120,55],[120,45]])
    centres_coord.append([150,50])
    # North Pole regular cell
    cells_coord.append([[102.34,85], [168.35,85], [279.26,85], [350.03,85]])
    centres_coord.append([0,90])
    # North Pole self crossing cell
    cells_coord.append([[135,85], [317,85], [225,85], [42,85]])
    centres_coord.append([140,87])
    # South Pole regular cell
    cells_coord.append([[42.24,-84.23],[317.76,-84.23],[225,-86.45],[135,-86.45]])
    centres_coord.append([0,-90])
    # South Pole clockwise cell
    cells_coord.append([[120,-87], [160,-80], [200,-80], [240,-87]])
    centres_coord.append([180,-82])
    # Fake masks and
    grid_in_size = len(centres_coord)
    grid_mask = np.zeros((grid_in_size))
else:
    start_time = time.time()
    print("Reading in files...")
    fin = netCDF4.Dataset(GridFile, 'r')
    kin = netCDF4.Dataset(MasksFile, 'r')
    if oasis_files:
        grid_in_size = len(fin.dimensions["x_"+gin]) * len(fin.dimensions["y_"+gin])
        grid_corners = len(fin.dimensions["crn_"+gin])
        #    grid_in_size = len(fin.dimensions["ni"]) * len(fin.dimensions["nj"])
        #    grid_corners = len(fin.dimensions["jpcr"])
    else:
        grid_in_size = len(fin.dimensions["x"]) * len(fin.dimensions["y"])
        grid_corners = len(fin.dimensions["crn"])

    grid_lat = fin.variables[gin+".lat"][:].flatten()
    grid_lon = fin.variables[gin+".lon"][:].flatten()
    grid_corner_lat = fin.variables[gin+".cla"][:].reshape(grid_corners,-1)
    grid_corner_lon = fin.variables[gin+".clo"][:].reshape(grid_corners,-1)

    grid_mask = kin.variables[gmn+".msk"][:].flatten()

    for i in range(grid_in_size):
        cells_coord.append([[grid_corner_lon[j,i],grid_corner_lat[j,i]] for j in range(grid_corners)])
        centres_coord.append([grid_lon[i],grid_lat[i]])
    print("Files are now loaded in {:.3f} secs.".format(time.time()-start_time))

# Shapely approach
ori_coord = deepcopy(cells_coord)
ori_centre = deepcopy(centres_coord)

# Transformation for high latitudes
Nproj = Proj('+proj=stere +lat_0=90')
Sproj = Proj('+proj=stere +lat_0=-90')

fig, axs = plt.subplots(3)
fig.set_size_inches(8.27,11.69)

nb_not_ok = 0
start_time = time.time()

#for i,c in enumerate(cells_coord):
for i in range(first_cell,grid_in_size):
    c = cells_coord[i]
    if (i+1)%10000 == 0:
        print('Processed {} points over {}, {:.0f}%'.format(i+1,grid_in_size,float(100*(i+1))/grid_in_size))
    if skip_mask and grid_mask[i] == 1:
        continue
    if any([j[1]>82 for j in c]):
        off = 10000
        ax = axs[1]
        r = LinearRing([Nproj(j[0],j[1]) for j in c])
        ctr = Point(Nproj(centres_coord[i][0],centres_coord[i][1]))
    elif any([j[1]<-82 for j in c]):
        off = 10000
        ax = axs[2]
        r = LinearRing([Sproj(j[0],j[1]) for j in c])
        ctr = Point(Sproj(centres_coord[i][0],centres_coord[i][1]))
    else:
        # Preprocess longitudes
        lons = np.array([j[0] for j in c])
        # Cell across periodicity
        if abs(np.max(lons)-np.min(lons)) > 100:
            blon = np.mean(lons)
            if abs(np.max(lons) - blon) > abs(np.min(lons) - blon):
                if abs(centres_coord[i][0] - np.min(lons)) > abs(np.max(lons) - centres_coord[i][0]):
                    centres_coord[i][0] -= 360.
                for j in c:
                    if j[0] > blon:
                        j[0] -= 360
            else:
                if abs(centres_coord[i][0] - np.min(lons)) < abs(np.max(lons) - centres_coord[i][0]):
                    centres_coord[i][0] += 360.
                for j in c:
                    if j[0] < blon:
                        j[0] += 360
        off = 2
        ax = axs[0]
        r = LinearRing(c)
        ctr = Point(centres_coord[i])

    convex = r.is_simple
    ccw = r.is_ccw
    poly = Polygon(r)
    centre = ctr.within(poly) or ctr.touches(poly)
    dupl_crn = duplicated_corners(r)
    dupli = len(dupl_crn) < 2
    not_dege = poly.area > 1.e-26
    cell_ok = not_dege and ccw and convex and centre and dupli

    if not cell_ok:
        nb_not_ok += 1
    if manual_input or not cell_ok:
        print('\n'+pdict[manual_input]['action']+'cell {} (fortran nr. {})'.format(i,i+1))
        print(pdict[manual_input]['dgen'][not_dege], pdict[manual_input]['dcvx'][convex], pdict[manual_input]['dccw'][ccw],
              pdict[manual_input]['dctr'][centre], pdict[manual_input]['ddup'][dupli])
        if not cell_ok and not terse_output:
            print('coord',ori_coord[i],'centre',ori_centre[i])
        if cell_ok:
            col = 'k'
        elif not not_dege:
            col = 'm'
        elif not convex:
            col = 'r'
        elif not centre:
            col = 'b'
        if manual_input:
            if not ccw:
                quiver_coords(ax, poly, col='c')
            else:
                plot_coords(ax, poly, col=col)
            plot_centres(ax, ctr, col)
            if not convex and not_dege:
                dupl_crn = duplicated_corners(r)
                ch = r.convex_hull
                plot_coords(ax, ch, col='g')
                lons = np.array(ch.boundary.xy[0])
                lats = np.array(ch.boundary.xy[1])
                convex_coords = []
                for i, x in enumerate(lons[:-1]):
                    rep = dupl_crn[(lons[i], lats[i])][1] if ((lons[i], lats[i]) in dupl_crn) else 1
                    lons[i] = fit_range(lons[i])
                    convex_coords.extend(rep*[[lons[i],lats[i]]])
                print('convex and ccw cell\ncoord',duplicated_to_end(convex_coords),'centre',ori_centre[i])
        else:
            if not convex or not not_dege:
                dupl_crn = duplicated_corners(r)
                plot_coords(ax, poly, col=col)
                if not terse_output and not_dege:
                    ch = r.convex_hull
                    plot_coords(ax, ch, col='g')
                    lons = np.array(ch.boundary.xy[0])
                    lats = np.array(ch.boundary.xy[1])
                    convex_coords = []
                    for i, x in enumerate(lons[:-1]):
                        rep = dupl_crn[(lons[i], lats[i])][1] if ((lons[i], lats[i]) in dupl_crn) else 1
                        lons[i] = fit_range(lons[i])
                        convex_coords.extend(rep*[[lons[i],lats[i]]])
                    print('convex and ccw cell\ncoord',duplicated_to_end(convex_coords),'centre',ori_centre[i])
            else:
                if not ccw:
                    quiver_coords(ax, poly, col='c')
                else:
                    if not centre:
                        plot_coords(ax, poly, col=col)
                        if not terse_output:
                            plot_centres(ax, ctr, col)
        if not terse_output:
            ax.annotate(str(i),[ctr.x+off, ctr.y])
        if stop_on_error:
            break

print('\nGrid full size = {}\nUnmskd grid size  = {}\nCells with problems = {}'\
      .format(grid_in_size,grid_in_size-np.sum(grid_mask),nb_not_ok))
print('Analysis took {:.3f} secs.'.format(time.time() - start_time))

# Plot wrong cells locations if any

if nb_not_ok > 0:
    plt.tight_layout()
    plt.show()
