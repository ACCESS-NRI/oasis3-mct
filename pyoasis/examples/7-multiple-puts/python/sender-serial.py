#!/usr/bin/env python3

import pyoasis
#AP from pyoasis.OasisParameters import *
import numpy as np

comp = pyoasis.Component("sender-serial")
print(comp)

n_points = 1
partition = pyoasis.SerialPartition(n_points)

#AP var_1 = pyoasis.Var("FSENDOCN_1", partition, OASIS_OUT)
var_1 = pyoasis.Var("FSENDOCN_1", partition, pyoasis.OasisParameters.OASIS_OUT)
print("Sender ",var_1)
#APvar_2 = pyoasis.Var("FSENDOCN_2", partition, OASIS_OUT)
var_2 = pyoasis.Var("FSENDOCN_2", partition, pyoasis.OasisParameters.OASIS_OUT)
print("Sender ",var_2)

comp.enddef()

for date in range(43201):
    
#AP    if var_1.put_inquire(date) == OASIS_SENT:
    if date%2400 == 0:
        var_1.put(date,pyoasis.asarray([date], dtype=np.float64))

#AP    if any([date%freq == 0 for freq in var_2.cpl_freqs]): #AP use a getter
#AP        pyoasis.debug_level = 2 #AP use a setter
        var_2.put(date,pyoasis.asarray([-1.*date], dtype=np.float64))
#AP        pyoasis.debug_level = 0 #AP use a setter
#AP        print("PyOasis debug level set to {}".format(pyoasis.debug_level)) #AP use a getter
        
pyoasis.terminate()
