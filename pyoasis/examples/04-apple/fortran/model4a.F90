PROGRAM model4a
  !
  ! Initialises an array with an apple partition and provides it via
  ! an OASIS3 put to another model with an apple partition.
  !
  use mod_oasis
  include 'mpif.h'

!  IMPLICIT NONE

  integer :: compid, ierror, local_comm, coupl_comm, kinfo, info
  integer :: var_type, part_id, date
  integer :: var_id, var_sh(2), partition(3), var_nodims(2), var_actual_shape(1)
  character(len=6) :: compname = "model4a"
  character(len=8) :: var_name = "FSENDOCN"
  real :: my_array(2)
  integer :: size, rank, i

  ! mpi_init is optional as it is called by oasis_init_comp
  ! CALL mpi_init(ierror)
 
  call oasis_init_comp(compid, compname, ierror)
  print *, "init_comp id=",compid," error=",ierror

  CALL oasis_get_localcomm(local_comm, ierror)
  print *, "get_localcomm local_comm=",local_comm," error=",ierror

  CALL mpi_comm_size(local_comm, size, ierror)
  CALL mpi_comm_rank(local_comm, rank, ierror)

  print *, "Hello from component", compname, " rank ", rank," of ",size

  ! The assumption in this example is that there are 5 MPI processes
  ! with each process having the 2 elements (my_array is of size 2) of
  ! the global (size 10 elements) mesh.
  if (size /= 5) call oasis_abort(compid, compname, "expecting 5 processes")

  CALL oasis_create_couplcomm(1, local_comm, coupl_comm, kinfo)
  print *, "create_couplcomm ",compname," coupl_comm=",coupl_comm," kinfo=",kinfo

  ! first value is 1 for apple partition
  ! second value is the global offset
  ! third value is 2 which is a fifth of our fictitious size 10 grid.
  partition=(/1, rank*2, 2/)
  CALL oasis_def_partition(part_id, partition, ierror)
  print *, "def_partition part_id=",part_id,"error=",ierror
  
  ! first value is unused, second value is the number of fields in a bundle
  var_nodims=(/1, 1/)
  CALL oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_OUT, &
       var_actual_shape, OASIS_REAL, ierror)
  print *,"def_var name=",var_name,"var_id=",var_id,"error=",ierror
  
  CALL oasis_enddef(ierror)
  print *, "enddef error=",ierror

  do i = 1, 2
     my_array(i) = rank
  end do

  date = 0
  call oasis_put(var_id, date, my_array, info)
  print *, "put var_id=",var_id,"info=",info

  CALL oasis_terminate(ierror)
  print *, "terminate error=",ierror

  ! mpi_finalize only needs to be called (after oasis_terminate) if
  ! mpi_init is explicitly called.
  ! call mpi_finalize(ierror)

END PROGRAM MODEL4a
