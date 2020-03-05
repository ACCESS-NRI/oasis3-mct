subroutine get_localcomm_iso(localcomm, kinfo) bind(C)
  use iso_c_binding, only: c_int
  use mod_oasis
  implicit none
  integer (c_int), intent(out) :: localcomm
  integer (c_int), intent(inout) :: kinfo

  integer :: localcomm_f, kinfo_f

  localcomm_f=localcomm
  kinfo_f=kinfo

  call oasis_get_localcomm(localcomm_f, kinfo_f)

  localcomm=localcomm_f
  kinfo=kinfo_f
  
end subroutine get_localcomm_iso


subroutine create_couplcomm_iso(icpl, allcomm, cplcomm, kinfo) bind(C)
  use iso_c_binding, only: c_int
  use mod_oasis
  implicit none
  integer (c_int), intent(in) :: icpl, allcomm
  integer (c_int), intent(out) :: cplcomm
  integer (c_int), intent(inout) :: kinfo

  integer :: icpl_f, allcomm_f, cplcomm_f, kinfo_f
  icpl_f=icpl
  allcomm_f=allcomm
  kinfo_f=kinfo

  call oasis_create_couplcomm(icpl_f, allcomm_f, cplcomm_f, kinfo_f)

  cplcomm=cplcomm_f
end subroutine create_couplcomm_iso


subroutine set_couplcomm_iso(localcomm, kinfo) bind(C)
  use iso_c_binding, only: c_int
  use mod_oasis
  implicit none
  integer (c_int), intent(in) :: localcomm 
  integer (c_int), intent(inout) :: kinfo
  
  integer :: localcomm_f
  integer :: kinfo_f
  
  localcomm_f=localcomm
  kinfo_f=kinfo
  
  call oasis_set_couplcomm(localcomm_f, kinfo_f)
  
  kinfo=kinfo_f
  
end subroutine set_couplcomm_iso


subroutine get_intercomm_iso(new_comm, cdnam, kinfo) bind(C)
  use iso_c_binding, only: c_int, c_ptr
  use pyoasis
  use mod_oasis
  implicit none
  integer (c_int), intent(out) :: new_comm 
  type(c_ptr), intent(in) :: cdnam
  integer (c_int), intent(out) :: kinfo
  
  integer :: new_comm_f 
  character(len=:), allocatable :: cdnam_f
  integer :: kinfo_f
  
  cdnam_f=string_to_fortran(cdnam)
  
  call oasis_get_intercomm(new_comm_f, cdnam_f, kinfo_f)
  
  new_comm=new_comm_f
  kinfo=kinfo_f
  
end subroutine get_intercomm_iso


subroutine get_intracomm_iso(new_comm, cdnam, kinfo) bind(C)
  use iso_c_binding, only: c_int, c_ptr
  use pyoasis
  use mod_oasis
  implicit none
  integer (c_int), intent(out) :: new_comm 
  type(c_ptr), intent(in) :: cdnam
  integer (c_int), intent(out) :: kinfo
  
  integer :: new_comm_f 
  character(len=:), allocatable :: cdnam_f
  integer :: kinfo_f
  
  cdnam_f=string_to_fortran(cdnam)
  
  call oasis_get_intracomm(new_comm_f, cdnam_f, kinfo_f)
  
  new_comm=new_comm_f
  kinfo=kinfo_f
  
end subroutine get_intracomm_iso
