!*********************************************************************************
SUBROUTINE hdlerr(istatus, line)
  !*********************************************************************************
  use netcdf
  implicit none
  !
  INCLUDE 'mpif.h'
  !
  ! Check for error message from NetCDF call
  !
  integer, intent(in) :: istatus, line
  integer             :: ierror
  !
  IF (istatus .NE. NF90_NOERR) THEN
      write ( * , * ) 'NetCDF problem in model1 or model2 at line',line
      write ( * , * ) 'Stopped '
      call MPI_Abort ( MPI_COMM_WORLD, 1, ierror )
  ENDIF
  !
  RETURN
END SUBROUTINE hdlerr
