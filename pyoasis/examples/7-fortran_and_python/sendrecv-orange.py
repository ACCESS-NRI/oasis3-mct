#!/usr/bin/python3

import pyoasis
import numpy

from mpi4py import MPI

# Test case for the most advanced partition and put/get options.
# Credits: Eric Maisonnave

comm = MPI.COMM_WORLD

component_name = "receiver"
print("Component name: " + component_name)

comp = pyoasis.Component(component_name, True, comm)
print("Component id: " + str(comp.get_id()))

comm_rank = comp.localcomm.rank
comm_size = comp.localcomm.size

n_points = 16

# Parameters for incoming partition

local_lons = (n_points//2)//comm_size
offsets = [comm_rank*local_lons,
           comm_rank*local_lons + (n_points//2)]
extents = [local_lons,
           local_lons]

# Parameters for outgoing partition: notice that the boxes extents
# do not sum up to n_points, hence the usually optional global_size
# argument of part_out __init__ is in this case mandatory

global_offsets = [0, 2, 4, 6]
extents_x = [0, 2, 0, 2]
extents_y = [0, 2, 0, 2]

# Use optional argument name of partitions __init__ for the case
# depicted in Oasis user guide as
# mandatory if oasis def partition is called either for a grid decomposed not across
# all the processes of a component or if the related oasis def partition are not 
# called in the same order on the different component processes

if comm_rank % 2 != 0:
    part_in = pyoasis.OrangePartition(offsets, extents, name="part_in")
    print("Part_in id: " + str(part_in.get_id()))

    part_out = pyoasis.BoxPartition(global_offsets[comm_rank],
                                    extents_x[comm_rank],
                                    extents_y[comm_rank],
                                    (n_points//2),
                                    global_size = n_points,
                                    name="part_out")
    print("Part_out id: " + str(part_out.get_id()))

else:
    part_out = pyoasis.BoxPartition(global_offsets[comm_rank],
                                    extents_x[comm_rank],
                                    extents_y[comm_rank],
                                    (n_points//2),
                                    global_size = n_points,
                                    name="part_out")
    print("Part_out id: " + str(part_out.get_id()))

    part_in = pyoasis.OrangePartition(offsets, extents, name="part_in")
    print("Part_in id: " + str(part_in.get_id()))


variable = pyoasis.Var("FRECVATM", part_in,
                       pyoasis.OasisParameters.OASIS_IN,
                       bundle_size = 2)
print("Variable FRECVATM id: " + str(variable.get_id()))

var_out = pyoasis.Var("FSENDATM", part_out,
                      pyoasis.OasisParameters.OASIS_OUT)
print("Variable FSENDATM id: " + str(variable.get_id()))

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

if comm_rank % 2 != 0:
    field = pyoasis.Array(bundle[:,:,1], dtype=numpy.float32)      
    date = int(0)
    var_out.put(date, field)
    
pyoasis.terminate()
