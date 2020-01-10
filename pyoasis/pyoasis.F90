#define MAX_LENGTH 1000


module pyoasis
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

end module pyoasis
