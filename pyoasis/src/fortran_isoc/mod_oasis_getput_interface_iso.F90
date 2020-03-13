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


subroutine oasis_put_iso(var_id, &
                         kstep, &
                         size1, size2, size3, &
                         field, &
                         kinfo) bind(C)
                             
  use iso_c_binding, only: c_int, c_double, c_ptr, c_bool
  use pyoasis
  use mod_oasis
  use mod_oasis_getput_interface
  
  use mod_oasis_kinds
  use mod_oasis_data
  use mod_oasis_parameters
  use mod_oasis_advance
  use mod_oasis_var
  use mod_oasis_sys
  use mct_mod
  
  implicit none

  integer (c_int), intent(in) :: var_id
  integer (c_int), intent(in) :: kstep
  integer (c_int), intent(in) :: size1, size2, size3
  real (c_double), intent(in) :: field(size1*size2*size3)
  integer (c_int), intent(out) :: kinfo
  integer :: var_id_f
  integer :: kstep_f
  integer :: kinfo_f
  integer :: sizes2(2)
  integer :: sizes3(3) 
  
  var_id_f=var_id
  kstep_f=kstep

  if(size3>1) then
    sizes3(1)=size1
    sizes3(2)=size2
    sizes3(3)=size3
    call oasis_put(var_id_f, kstep_f, reshape(field, sizes3), kinfo_f)
  else if(size2>1) then
    sizes2(1)=size1
    sizes2(2)=size2   
    call oasis_put(var_id_f, kstep_f, reshape(field, sizes2), kinfo_f)
  else
    call oasis_put(var_id_f, kstep_f, field, kinfo_f)
  end if
    
  kinfo=kinfo_f
end subroutine oasis_put_iso



subroutine oasis_get_iso(var_id, kstep, size1, size2, size3, field, kinfo) bind(C)
  use iso_c_binding, only: c_int, c_double, c_ptr, c_bool
  use pyoasis
  use mod_oasis
  use mod_oasis_getput_interface
  use mod_oasis_kinds
  use mod_oasis_data
  use mod_oasis_parameters
  use mod_oasis_advance
  use mod_oasis_var
  use mod_oasis_sys
  use mct_mod 
  implicit none
  
  integer (c_int), intent(in) :: var_id
  integer (c_int), intent(in) :: kstep
  integer (c_int), intent(in) :: size1, size2, size3
  real (c_double), intent(inout) :: field(size1*size2*size3)
  integer(c_int) , intent(out):: kinfo
  integer :: var_id_f
  integer :: kstep_f
  integer :: kinfo_f
  integer :: sizes1(1)
  integer :: sizes2(2)
  integer :: sizes3(3)
  real, allocatable :: field1(:)
  real, allocatable :: field2(:,:)
  real, allocatable :: field3(:,:,:)
  
  var_id_f=var_id
  kstep_f=kstep
   
  if(size3>1) then
    sizes3(1)=size1
    sizes3(2)=size2
    sizes3(3)=size3
    field3=reshape(field, sizes3)
    call oasis_get(var_id_f, kstep_f, field3, kinfo_f)
  else if(size2>1) then
    sizes2(1)=size1
    sizes2(2)=size2   
    field2=reshape(field, sizes2)
    call oasis_get(var_id_f, kstep_f, field2, kinfo_f)
  else
    call oasis_get(var_id_f, kstep_f, field, kinfo_f)
  end if
  
  kinfo=kinfo_f
  
end subroutine oasis_get_iso
