!*********************************************************************************
SUBROUTINE hdlerr(status,w_unit,subn,file,line)
  !*********************************************************************************
  use netcdf
  implicit none
  !
  INCLUDE 'mpif.h'
  !
  ! Check for error message from NetCDF call
  !
  integer, intent(in)          :: status, line, w_unit
  character(len=*), intent(in) :: subn
  character(len=*), intent(in) :: file
  integer                      :: ierror
  !
  IF (status .NE. NF90_NOERR) THEN
     write(w_unit,*) 'NetCDF Problem in routine : ',trim(subn)
     CALL FLUSH(w_unit)
     call routine_model_abort(w_unit,file,line)
  ENDIF
  !
  RETURN
END SUBROUTINE hdlerr