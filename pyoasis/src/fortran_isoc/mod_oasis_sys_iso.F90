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


subroutine oasis_abort_iso(comp_id, routine, message, filename, line, error) bind(C)
  use iso_c_binding, only: c_int, c_ptr
  use pyoasis
  use mod_oasis
  implicit none
  integer(kind=c_int), intent(in) :: comp_id
  type(c_ptr), intent(in) :: routine
  type(c_ptr), intent(in) :: message
  type(c_ptr), intent(in) :: filename
  integer(kind=c_int), intent(in) :: line
  integer(kind=c_int), intent(in) :: error

  integer :: comp_id_f
  character(len=:), allocatable :: routine_f, message_f, filename_f
  integer :: line_f, error_f

  comp_id_f=comp_id
  routine_f=string_to_fortran(routine)
  message_f=string_to_fortran(message)
  filename_f=string_to_fortran(filename)
  line_f=line
  error_f=error
      
  call oasis_abort(comp_id_f, routine_f, message_f, filename_f, line_f, error_f)    
end subroutine oasis_abort_iso
