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
