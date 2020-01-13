#!/usr/bin/python

from ctypes import *
import ctypes

import numpy

cdll.LoadLibrary("libpyoasiscore.so")
lib=CDLL("libpyoasiscore.so")



lib.oasis_abort.argtypes=[ctypes.c_int, c_char_p, c_char_p, c_char_p, c_int, c_int]
def oasis_abort(comp_id, routine, message, filename, line, error):
  lib.oasis_abort(comp_id, routine.encode(), message.encode(), filename.encode(), line, error)

