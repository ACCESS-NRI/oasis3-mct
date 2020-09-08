SUBROUTINE flddiag(field,fmin,fmax,fsum,comm,nx,ny)
  !***************************************************************************

  use mod_oasis_kinds
  use mod_oasis_mpi

  IMPLICIT NONE

  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double

  integer,  intent(in)  :: nx,ny
  real(wp), intent(in)  :: field(nx,ny)
  real(wp), intent(out) :: fmin,fmax,fsum
  integer,  intent(in)  :: comm

  real(ip_double_p) :: lvali
  real(ip_double_p) :: lvalo

  lvali = minval(field)
  call oasis_mpi_min(lvali,lvalo,comm)
  fmin = lvalo

  lvali = maxval(field)
  call oasis_mpi_max(lvali,lvalo,comm)
  fmax = lvalo

  lvali = sum(field)
  call oasis_mpi_sum(lvali,lvalo,comm)
  fsum = lvalo

END SUBROUTINE flddiag

