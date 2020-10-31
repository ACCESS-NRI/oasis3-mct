#!/usr/bin/env python3

import pyoasis
#AP from pyoasis.OasisParameters import *
import numpy as np

comp = pyoasis.Component("receiver_two")
print(comp)

n_points = 1
partition = pyoasis.SerialPartition(n_points)

#var_1 = pyoasis.Var("FRECVICE_1", partition, OASIS_IN)
var_1 = pyoasis.Var("FRECVICE_1", partition, pyoasis.OasisParameters.OASIS_IN)
print("Recv_two ",var_1)

#var_2 = pyoasis.Var("FRECVICE_2", partition, OASIS_IN)
var_2 = pyoasis.Var("FRECVICE_2", partition, pyoasis.OasisParameters.OASIS_IN)
print("Recv_two ",var_2)

comp.enddef()

field = pyoasis.asarray(np.zeros(n_points, dtype=np.float64))

for date in range(43201):
    if date%2400 == 0:
#AP    if any([date%freq == 0 for freq in var_1.cpl_freqs]):
        var_1.get(date,field)
        if abs((field - date).sum()) < 1.e-8:
            print("Recv_two: field 1 received successfully at time {}".format(date))
        else:
            print("Warning: Recv_two at time {} got {} instead of {}".format(date,field[0],date))

#AP    if any([date%freq == 0 for freq in var_2.cpl_freqs]):
        var_2.get(date,field)
        if abs((field + date).sum()) < 1.e-8:
            print("Recv_two: field 2 received successfully at time {}".format(date))
        else:
            print("Warning: Recv_two at time {} got {} instead of {}".format(date,field[0],date))

comp.terminate()
