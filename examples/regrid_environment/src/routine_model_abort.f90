!*********************************************************************************
SUBROUTINE routine_model_abort(w_unit,file,line,subn)
  !*********************************************************************************
  !
  implicit none
  !
  INCLUDE 'mpif.h'
  !
  ! Call abort in a toy model
  !
  integer, intent(in)                    :: w_unit, line
  character(len=*), intent(in), optional :: subn
  character(len=*), intent(in)           :: file
  integer                                :: ierror
  character(len=*),parameter             :: subname = '(oasis_abort)'
  !
  !
  WRITE (w_unit,*) subname,' Aborting at line = ',line
  call flush(w_unit)
  !
  if (present(subn)) then
       WRITE (w_unit,*) subname,' Aborting in = ',trim(subn)
       call flush(w_unit)
  endif

  WRITE (w_unit,*) subname,' Aborting in file : ',file
  call flush(w_unit)

  call MPI_Abort ( MPI_COMM_WORLD, 1, ierror )
  !
  RETURN
END SUBROUTINE routine_model_abort