subroutine oasis_def_var_iso(id_nports, cdport, id_part, &
           id_var_nodims, kinout, n, id_var_shape, ktype, kinfo)
  use iso_c_binding, only: c_int, c_ptr, c_bool
  use pyoasis
  use mod_oasis
  implicit none
  include "mpif.h"
  integer (c_int), intent(out) :: id_nports
  type(c_ptr), intent(in) :: cdport
  integer (c_int), intent(in) :: id_part
  integer (c_int), intent(in) :: id_var_nodims(2)
  integer (c_int), intent(in) :: kinout
  integer (c_int), intent(in) :: n 
  integer (c_int), intent(in) :: id_var_shape(:) 
  integer (c_int), intent(in) :: ktype
  integer (c_int), intent(out) :: kinfo
  
  integer :: id_nports_f
  character(len=:), allocatable :: cdport_f
  integer :: id_part_f
  integer :: id_var_nodims_f(2)
  integer kinout_f
  integer :: id_var_shape_f(n) 
  integer :: ktype_f
  integer :: kinfo_f
  
  integer :: i
  return
  cdport_f=string_to_fortran(cdport)
  id_part_f=id_part
  id_var_nodims_f(1)=id_var_nodims(1)
  id_var_nodims_f(2)=id_var_nodims(2)
  kinout_f=kinout
  do i=1, n 
    id_var_shape_f(i)=id_var_shape(i)
  end do
  ktype_f=ktype
  
  call oasis_def_var(id_nports_f, cdport_f, id_part_f, &
  id_var_nodims_f, kinout_f, id_var_shape_f, ktype_f, kinfo_f)
  
  id_nports=id_nports_f
  kinfo=kinfo_f
end subroutine oasis_def_var_iso
  
