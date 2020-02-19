PROGRAM model3a
  !
  ! Initialises an array and provides it via an OASIS3 put.
  !
  use mod_oasis

  IMPLICIT NONE

  integer :: compid, ierror, local_comm, coupl_comm, kinfo, info, i
  integer :: var_type, part_id, date
  integer :: var_id, var_sh(2), partition(3), var_nodims(2), var_actual_shape(1)
  character(len=7) :: compname = "model3a"
  character(len=8) :: var_name = "FSENDOCN"
  real :: my_array(10)

  print *, "Hello from component ",compname

  call oasis_init_comp(compid, compname, ierror)
  print *, "init_comp id=",compid," error=",ierror

  CALL oasis_get_localcomm(local_comm, ierror)
  print *, "get_localcomm local_comm=",local_comm," error=",ierror

  CALL oasis_create_couplcomm(1, local_comm, coupl_comm, kinfo)
  print *, "create_couplcomm ",compname," coupl_comm=",coupl_comm," kinfo=",kinfo
  ! first value is 0 for serial partition
  ! second value is unused
  ! third value is 10 which is the total size of our fictitious grid
  partition=(/0, 0, 10/)
  CALL oasis_def_partition(part_id, partition, ierror)
  print *, "def_partition part_id=",part_id," error=",ierror
  
  ! first value is unused, second value is the number of fields in a bundle
  var_nodims=(/1, 1/)
  var_actual_shape=1
  print *, "AAAAA " , " / ", var_name," / ", part_id, " / ", &
       var_nodims, " / ", OASIS_OUT, " / ", var_actual_shape, " / ", OASIS_REAL
  CALL oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_OUT, &
       var_actual_shape, OASIS_REAL, ierror)
  print *,"def_var name=",var_name," var_id=",var_id," error=",ierror
  
  CALL oasis_enddef(ierror)
  print *, "enddef error=",ierror

  do i = 1, 10
     my_array(i) = i
  end do
  
  date = 0
  if (var_id /= -1) then
  call oasis_put(var_id, date, my_array, info)
  print *, "put var_id=",var_id," info=",info
  endif

  CALL oasis_terminate(ierror)
  print *, "terminate error=",ierror
  !
END PROGRAM MODEL3a
