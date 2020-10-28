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


subroutine oasis_put_iso_double(var_id, &
                                kstep, &
                                size1, size2, size3, &
                                field, &
                                kinfo) BIND(C)
                             
  use iso_c_binding, only: c_int, c_double, c_ptr, c_bool
  use cbindings
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

  integer (c_int), intent(in)         :: var_id
  integer (c_int), intent(in)         :: kstep
  integer (c_int), intent(in)         :: size1, size2, size3
  real (c_double), intent(in), target :: field(size1*size2*size3)
  integer (c_int), intent(out)        :: kinfo
  integer :: var_id_f
  integer :: kstep_f
  integer :: kinfo_f
  real (c_double), pointer :: field2(:,:)
  real (c_double), pointer :: field3(:,:,:)
  
  var_id_f=var_id
  kstep_f=kstep

  if(size3>1) then
    field3(1:size1,1:size2,1:size3)=>field(:)
    call oasis_put(var_id_f, kstep_f, field3, kinfo_f)
  else if(size2>1) then
    field2(1:size1,1:size2)=>field(:)
    call oasis_put(var_id_f, kstep_f, field2, kinfo_f)
  else
    call oasis_put(var_id_f, kstep_f, field, kinfo_f)
  end if
    
  kinfo=kinfo_f

end subroutine oasis_put_iso_double



subroutine oasis_get_iso_double(var_id, kstep, size1, size2, size3, field, kinfo) bind(C)
  use iso_c_binding, only: c_int, c_double, c_ptr, c_bool
  use cbindings
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
  
  integer (c_int), intent(in)            :: var_id
  integer (c_int), intent(in)            :: kstep
  integer (c_int), intent(in)            :: size1, size2, size3
  real (c_double), intent(inout), target :: field(size1*size2*size3)
  integer(c_int) , intent(out)           :: kinfo
  integer :: var_id_f
  integer :: kstep_f
  integer :: kinfo_f
  real (c_double), pointer :: field2(:,:)
  real (c_double), pointer :: field3(:,:,:)
  
  var_id_f=var_id
  kstep_f=kstep
   
  if(size3>1) then
    field3(1:size1,1:size2,1:size3)=>field(:)
    call oasis_get(var_id_f, kstep_f, field3, kinfo_f)
  else if(size2>1) then
    field2(1:size1,1:size2)=>field(:)
    call oasis_get(var_id_f, kstep_f, field2, kinfo_f)
  else
    call oasis_get(var_id_f, kstep_f, field, kinfo_f)
  end if
  
  kinfo=kinfo_f
  
end subroutine oasis_get_iso_double


subroutine oasis_put_iso_float(var_id, &
                               kstep, &
                               size1, size2, size3, &
                               field, &
                               kinfo) BIND(C)
                             
  use iso_c_binding, only: c_int, c_float, c_ptr, c_bool
  use cbindings
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

  integer (c_int), intent(in)         :: var_id
  integer (c_int), intent(in)         :: kstep
  integer (c_int), intent(in)         :: size1, size2, size3
  real (c_float),  intent(in), target :: field(size1*size2*size3)
  integer (c_int), intent(out)        :: kinfo
  integer :: var_id_f
  integer :: kstep_f
  integer :: kinfo_f
  real (c_float), pointer :: field2(:,:)
  real (c_float), pointer :: field3(:,:,:)
  
  var_id_f=var_id
  kstep_f=kstep

  if(size3>1) then
    field3(1:size1,1:size2,1:size3)=>field(:)
    call oasis_put(var_id_f, kstep_f, field3, kinfo_f)
  else if(size2>1) then
    field2(1:size1,1:size2)=>field(:)
    call oasis_put(var_id_f, kstep_f, field2, kinfo_f)
  else
    call oasis_put(var_id_f, kstep_f, field, kinfo_f)
  end if
    
  kinfo=kinfo_f

end subroutine oasis_put_iso_float



subroutine oasis_get_iso_float(var_id, kstep, size1, size2, size3, field, kinfo) bind(C)
  use iso_c_binding, only: c_int, c_float, c_ptr, c_bool
  use cbindings
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
  
  integer (c_int), intent(in)            :: var_id
  integer (c_int), intent(in)            :: kstep
  integer (c_int), intent(in)            :: size1, size2, size3
  real (c_float),  intent(inout), target :: field(size1*size2*size3)
  integer(c_int) , intent(out)           :: kinfo
  integer :: var_id_f
  integer :: kstep_f
  integer :: kinfo_f
  real (c_float), pointer :: field2(:,:)
  real (c_float), pointer :: field3(:,:,:)
  
  var_id_f=var_id
  kstep_f=kstep
   
  if(size3>1) then
    field3(1:size1,1:size2,1:size3)=>field(:)
    call oasis_get(var_id_f, kstep_f, field3, kinfo_f)
  else if(size2>1) then
    field2(1:size1,1:size2)=>field(:)
    call oasis_get(var_id_f, kstep_f, field2, kinfo_f)
  else
    call oasis_get(var_id_f, kstep_f, field, kinfo_f)
  end if
  
  kinfo=kinfo_f
  
end subroutine oasis_get_iso_float
