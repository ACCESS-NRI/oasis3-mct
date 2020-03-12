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
