! pyOASIS - A Python wrapper for OASIS
! Authors: Philippe Gambron, Rupert Ford
! Copyright (C) 2019 UKRI - STFC

! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU Lesser General Public License as 
! published by the Free Software Foundation, either version 3 of the 
! License, or any later version.

! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
! GNU Lesser General Public License for more details.

! A copy of the GNU Lesser General Public License, version 3, is supplied
! with this program, in the file lgpl-3.0.txt. It is also available at 
! <https://www.gnu.org/licenses/lgpl-3.0.html>.


subroutine init_comp_iso(comp_id, comp_name, error, coupled, communicator) bind(C)
  use iso_c_binding, only: c_int, c_ptr, c_bool
  use pyoasis
  use mod_oasis
  implicit none
  include "mpif.h"
  integer (c_int), intent(out) :: comp_id   
  type(c_ptr), intent(in) :: comp_name 
  integer (c_int), intent(out) :: error
  logical (c_bool), intent(in) :: coupled
  integer (c_int), intent(in) :: communicator

  integer :: comp_id_f
  character(len=:), allocatable :: comp_name_f
  integer :: error_f
  logical :: coupled_f
  integer :: communicator_f

  comp_name_f=string_to_fortran(comp_name)
  coupled_f=coupled
  communicator_f=communicator
  
  call oasis_init_comp(comp_id_f, comp_name_f, error_f, coupled_f, communicator_f)

  comp_id=comp_id_f
  error=error_f
end subroutine init_comp_iso


subroutine enddef_iso(kinfo) bind(C)
  use iso_c_binding, only: c_int
  use mod_oasis
  implicit none
  integer (c_int), intent(inout) :: kinfo

  integer :: kinfo_f

  kinfo_f=kinfo
  
  call oasis_enddef(kinfo_f)
  
  kinfo=kinfo_f
end subroutine enddef_iso


subroutine terminate_iso(kinfo) bind(C)
  use iso_c_binding, only: c_int
  use mod_oasis
  implicit none
  integer (c_int), intent(inout) :: kinfo

  integer :: kinfo_f

  kinfo_f=kinfo
  call oasis_terminate(kinfo_f)
  kinfo=kinfo_f
end subroutine terminate_iso


subroutine get_comm_size_iso(communicator, comm_size, error) bind(C)
  use iso_c_binding, only: c_int
  implicit none
  include "mpif.h"
  integer (c_int), intent(in) :: communicator
  integer (c_int), intent(out) :: error, comm_size

  integer communicator_f, comm_size_f, error_f 
  
  communicator_f=communicator
  
  call mpi_comm_size(communicator_f, comm_size_f, error_f)
  
  comm_size=comm_size_f
  error=error_f
end subroutine get_comm_size_iso


subroutine get_comm_rank_iso(communicator, comm_rank, error) bind(C)
  use iso_c_binding, only: c_int
  implicit none
  include "mpif.h"
  integer (c_int), intent(in) :: communicator
  integer (c_int), intent(out) :: error, comm_rank

  integer communicator_f, comm_rank_f, error_f 
  
  communicator_f=communicator
  
  call mpi_comm_rank(communicator_f, comm_rank_f, error_f)
  
  comm_rank=comm_rank_f
  error=error_f
end subroutine get_comm_rank_iso
