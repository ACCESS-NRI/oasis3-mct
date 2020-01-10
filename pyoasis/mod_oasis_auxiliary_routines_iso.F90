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


subroutine oasis_set_debug_iso(debug,kinfo) bind(C)
  use iso_c_binding, only: c_int
  use pyoasis
  use mod_oasis
  implicit none
  
  integer(c_int), intent(in) :: debug
  integer(c_int), intent(inout) :: kinfo
  
  integer :: debug_f
  integer :: kinfo_f
  
  debug_f=debug;
  
  call oasis_set_debug(debug_f, kinfo_f)
  
  kinfo=kinfo_f
end subroutine oasis_set_debug_iso

  
subroutine oasis_get_debug_iso(debug,kinfo) bind(C)
  use iso_c_binding, only: c_int
  use pyoasis
  use mod_oasis
  implicit none
  
  integer(c_int), intent(out) :: debug
  integer(c_int), intent(inout) :: kinfo
  
  integer :: debug_f
  integer :: kinfo_f
  
  call oasis_set_debug(debug_f, kinfo_f)
  
  debug=debug_f;
  kinfo=kinfo_f
end subroutine oasis_get_debug_iso



subroutine oasis_put_inquire_iso(varid, msec, kinfo) bind(C)
  use iso_c_binding, only: c_int
  use pyoasis
  use mod_oasis
  implicit none
  integer(c_int), intent(in) :: varid
  integer(c_int), intent(in) :: msec
  integer(c_int), intent(out) :: kinfo
  
  integer :: varid_f
  integer :: msec_f
  integer :: kinfo_f
  
  varid_f=varid
  msec_f=msec
  
  call oasis_put_inquire(varid_f, msec_f, kinfo_f)
  
  kinfo=kinfo_f
  
end subroutine oasis_put_inquire_iso


subroutine oasis_get_ncpl_iso(varid, ncpl, kinfo) bind(C)
  use iso_c_binding, only: c_int
  use pyoasis
  use mod_oasis
  implicit none
  integer(c_int), intent(in) :: varid
  integer(c_int), intent(out) :: ncpl
  integer(c_int), intent(out) :: kinfo
 
  integer :: varid_f
  integer :: ncpl_f
  integer :: kinfo_f
  
  varid_f=varid
  
  call oasis_get_ncpl(varid_f, ncpl_f, kinfo_f)
  
  ncpl=ncpl_f
  kinfo=kinfo_f
   
end subroutine oasis_get_ncpl_iso


subroutine oasis_get_freqs_iso(varid, mop, ncpl, cpl_freqs, kinfo) bind(C)
  use iso_c_binding, only: c_int
  use pyoasis
  use mod_oasis
  implicit none
  integer(c_int), intent(in) :: varid        
  integer(c_int), intent(in) :: mop        
  integer(c_int), intent(in) :: ncpl       
  integer(c_int), intent(out) :: cpl_freqs(ncpl)
  integer(c_int), intent(out) :: kinfo          
  
  integer :: varid_f
  integer :: mop_f
  integer :: ncpl_f
  integer :: kinfo_f
  
  varid_f=varid
  mop_f=mop
  ncpl_f=ncpl
  
  call oasis_get_freqs(varid_f, mop_f, ncpl_f, cpl_freqs, kinfo_f)

  kinfo=kinfo_f
  
end subroutine oasis_get_freqs_iso
