#!/usr/bin/python3


import pytest
import pyoasis


def returns_zero(*args):
    return 0


def returns_2_zeros(*args):
    return [0, 0]

def test_component():
    pyoasis.mod_oasis_method.init_comp=returns_2_zeros
    pyoasis.mod_oasis_auxiliary_routines.get_localcomm=returns_2_zeros
    pyoasis.mod_oasis_auxiliary_routines.create_couplcomm=returns_2_zeros
    pyoasis.mod_oasis_auxiliary_routines.get_comm_size=returns_2_zeros
    pyoasis.mod_oasis_auxiliary_routines.get_comm_rank=returns_2_zeros
    
    name = "my_component"
    comp = pyoasis.Component(name)
    assert comp.get_name() == name
    assert comp.get_id() >= 0
    assert comp.get_localcomm() >= 0
    assert comp.create_couplcomm(comp.get_localcomm()) >= 0
    assert comp.get_comm_size() >= 0
    assert comp.get_comm_rank() >= 0
    assert comp.get_localcomm_size() >= 0
    assert comp.get_localcomm_rank() >= 0

    
def test_SerialPartition():
    pyoasis.mod_oasis_part.def_partition=returns_2_zeros
    n_points = 10
    serial_partition = pyoasis.SerialPartition(n_points)
    assert serial_partition.get_id() >= 0


def test_ApplePartition():
    pyoasis.mod_oasis_part.def_partition=returns_2_zeros
    offset = 0
    n_points = 10
    apple_partition = pyoasis.ApplePartition(offset, n_points)
    assert apple_partition.get_id() >= 0


def test_BoxPartition():
    pyoasis.mod_oasis_part.def_partition=returns_2_zeros
    global_offset = 0
    local_extent_x = 10
    local_extent_y = 10
    global_extent_x = 10
    box_partition=pyoasis.BoxPartition(global_offset, local_extent_x,
                                       local_extent_y, global_extent_x)
    assert box_partition.get_id() >= 0


def test_PointsPartition():
    pyoasis.mod_oasis_part.def_partition=returns_2_zeros
    n_points=10
    global_indices=range(n_points)
    points_partition=pyoasis.PointsPartition(global_indices)
    assert points_partition.get_id() >= 0

def test_Var():
    pyoasis.mod_oasis_part.def_partition = returns_2_zeros
    pyoasis.mod_oasis_var.def_var = returns_2_zeros
    name = "my_var"
    n_points = 10
    partition = pyoasis.SerialPartition(n_points)
    rank_number = [0, 1] 
    variable = pyoasis.Var(name, partition, rank_number,
                           pyoasis.OasisParameters.OASIS_OUT)    
    assert variable.get_name() == name
    assert variable.get_id() >= 0

 
