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

#define MAX_LENGTH 1000


module cbindings
  implicit none    
  contains
      
    function string_to_fortran(string_c)
      use iso_c_binding, only: c_int, c_ptr, c_f_pointer, C_NULL_CHAR
      implicit none 
      type(c_ptr), intent(in) :: string_c
      character, pointer :: p_char(:)
      character(MAX_LENGTH) :: long_string
      character :: char
      character(len=:), allocatable :: string_to_fortran
      integer i
      
      call c_f_pointer(string_c, p_char, [MAX_LENGTH])
      
      do i=1, MAX_LENGTH
        char=p_char(i)
        if (char==C_NULL_CHAR) then
          exit
        end if
        long_string(i:i)=char
      end do
      
      allocate(character(len=i-1) :: string_to_fortran)
      string_to_fortran=long_string(1:i-1)
    end function string_to_fortran


    function string_to_c(string_f) 
      use iso_c_binding, only: c_ptr, c_f_pointer, C_NULL_CHAR
      implicit none
      CHARACTER(len=*), intent(in) :: string_f
      character, pointer :: p_char(:)
      type(c_ptr), target :: string_to_c
      integer i, length

      length=len(string_f)
      call c_f_pointer(string_to_c, p_char, [length])
      do i=1,length
        p_char(i)=string_f(i:i)
      end do
      p_char(length+1)=C_NULL_CHAR
    end function string_to_c

end module cbindings
