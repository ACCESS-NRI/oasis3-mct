program receiver_serial
   use mod_oasis
   implicit none
   integer :: kinfo
   integer :: comp_id, part_id
   character(len=15) :: comp_name = "receiver-serial"
   integer :: n_points, date
   integer :: part_params(3)
   integer :: var_id, var_nodims(2)
   character(len=8) :: var_name = "FRECVICE"
   real(kind=4), allocatable, dimension(:) :: field
   
   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) then
      print *, "Error in oasis_init_comp: ", kinfo
      stop
   endif

   print '(3A,I0)', "Component name: ", trim(comp_name), " = Component ID: ", comp_id

   n_points=16

   part_params=(/0, 0, n_points/)
   call oasis_def_partition(part_id, part_params, kinfo)
   if(kinfo<0) then
      print *, "Error in oasis_def_partition: ", kinfo
      stop
   endif
   print '(2A,I0)', trim(comp_name),": part_id: ", part_id
   
  var_nodims=(/1, 1/)
  
  call oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_IN, &
                    (/1/), OASIS_REAL, kinfo)
  if(kinfo<0 .or. var_id<0) then
    print *, "Error in oasis_def_var: ", kinfo
    stop
  endif 
  print '(4A,I0)', trim(comp_name),": var_name: ", trim(var_name), &
     & " = var_id: ", var_id

  call oasis_enddef(kinfo)
  if(kinfo<0) then
    print *, "Error in oasis_enddef: ", kinfo
    stop
  endif

  allocate(field(n_points))
  field(:) = 999.

  date = 0

  call oasis_get(var_id, date, field, kinfo)

  if(kinfo<0) then
    print *, "Error in oasis_put: ", kinfo
    stop
  endif

  print *, 'FRECVICE = '
  print '(8F6.0)', field

  deallocate(field)
  
end program receiver_serial
