#!/usr/bin/python3

import pyoasis
import numpy

from mpi4py import MPI


comm = MPI.COMM_WORLD

component_name = "receiver"
print("Component name: " + component_name)

comp = pyoasis.Component(component_name, True, comm)
print("Component id: " + str(comp.get_id()))

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

n_points = 16

local_lons = (n_points//2)//comm_size
offsets = [comm_rank*local_lons,
           comm_rank*local_lons + (n_points//2)]
extents = [local_lons,
           local_lons]

print('Comm rank {}'.format(comm_rank), offsets, extents, flush=True)

partition = pyoasis.OrangePartition(offsets, extents)
print("Partition id: " + str(partition.get_id()))

variable = pyoasis.Var("FRECVATM", partition,
                       pyoasis.OasisParameters.OASIS_IN,
                       bundle_size = 2)
print("Variable id: " + str(variable.get_id()))

comp.enddef()

date = int(0)
bundle = pyoasis.Array(numpy.zeros((local_lons,2,2),
                                   dtype=numpy.float64))

variable.get(date, bundle)

expected_bundle = pyoasis.Array(numpy.zeros((local_lons,2,2),
                                            dtype=numpy.float64))
for i in range(2):
    expected_bundle[:,:,i] = i + 1
for i in range(local_lons):
    expected_bundle[i,:,:] += (i + 1 + comm_rank*local_lons) * 100
for i in range(2):
    expected_bundle[:,i,:] += (i + 1) * 10

epsilon = 1e-8
error = abs((bundle-expected_bundle).sum())
if(error < epsilon):
    print("Data received successfully")

for i in range(2):
    print("Bundle {} is".format(i+1))
    print(bundle[:,0,i])
    print(bundle[:,1,i])

print("Element (0,1) of first bundle is {}".format(bundle[0,1,0]))

pyoasis.terminate()
