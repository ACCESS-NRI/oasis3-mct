program sender_serial
  use mod_oasis
  implicit none
  integer :: i, kinfo
  integer :: comp_id, local_comm, coupl_comm
  integer :: n_points, var_type, part_id
  integer :: part_params(3), offset, local_size
  integer :: comm_size, comm_rank
  integer :: var_id, var_nodims(2), var_actual_shape(1), date
  character(len=13) :: comp_name = "sender-serial"
  character(len=8) :: var_name = "FSENDOCN"
  real :: field(4)

  print *, "Component name: ", comp_name
	
  call oasis_init_comp(comp_id, comp_name, kinfo)
  if(kinfo<0) then
    print *, "Error in oasis_init_comp: ", kinfo
    return
  endif
  print *, "Component ID: ", comp_id
  
  call oasis_get_localcomm(local_comm, kinfo)
  if(kinfo<0) then
    print *, "Error in oasis_get_localcomm: ", kinfo
    return
  endif
  print *, "local_comm=",local_comm

  call oasis_create_couplcomm(1, local_comm, coupl_comm, kinfo)
  print *, "coupl_comm ", coupl_comm
  if(kinfo<0) then
    print *, "Error in oasis_create_couplcomm: ", kinfo
    return
  endif
  print *, "coupl_comm ", coupl_comm

  call mpi_comm_size(local_comm, comm_size, kinfo)
  call mpi_comm_rank(local_comm, comm_rank, kinfo)
  
  n_points=16
  
  local_size=n_points/comm_size
  offset=comm_rank*local_size

  part_params=(/1, offset, local_size/)
  call oasis_def_partition(part_id, part_params, kinfo)
  if(kinfo<0) then
    print *, "Error in oasis_def_partition: ", kinfo
    return
  endif
  print *, "part_id: ", part_id
	
  var_nodims=(/1, 1/)
  var_actual_shape=1
  print *, "var_name: ", var_name
  call oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_OUT, &
                    var_actual_shape, OASIS_REAL, kinfo)
  if(kinfo<0 .or. var_id<0) then
    print *, "Error in oasis_def_partition: ", kinfo
    return
  endif 
  print *, "var_id: ", var_id
  
  call oasis_enddef(kinfo)
  if(kinfo<0) then
    print *, "Error in oasis_enddef: ", kinfo
    return
  endif

  do i=0, local_size
    field(i)=i
  end do
	
  date=0
	
  call oasis_put(var_id, date, field, kinfo)

  if(kinfo<0) then
    print *, "Error in oasis_put: ", kinfo
    return
  endif

  call oasis_terminate(kinfo)
  if(kinfo<0) then
    print *, "Error in oasis_terminate: ", kinfo
  endif

end program sender_serial 
