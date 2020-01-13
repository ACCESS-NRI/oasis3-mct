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
  
  integer :: rank
  comp_name_f=string_to_fortran(comp_name)
  coupled_f=coupled
  communicator_f=communicator
  print *, "=== > name:", comp_name_f, " coupled:", coupled_f, " communicator:", communicator_f

  call oasis_init_comp(comp_id_f, comp_name_f, error_f, coupled_f, communicator_f)
  print *, "=== < id:", comp_id_f, " error:", error_f
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
