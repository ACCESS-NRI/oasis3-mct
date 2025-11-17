program sender_apple
   use mpi
   use mod_oasis
   use netcdf
   implicit none
   integer :: i, kinfo, date
   integer :: comp_id, part_id, sca_id, frc_id, nor_id
   integer :: part_params(OASIS_Apple_Params), offset, local_size
   integer :: local_comm, comm_size, comm_rank
   integer :: var_nodims(2)
   character(len=13) :: comp_name = "sender-apple"
   character(len=8) :: sca_name = "FSENDSCA"
   character(len=8) :: frc_name = "FSENDFRC"
   character(len=8) :: nor_name = "FSENDNOR"
   real(kind=8), allocatable :: field(:)
   real(kind=8), allocatable :: scaled(:)
   real(kind=8), allocatable :: frac(:)
   integer, parameter :: nx_global = 362, ny_global = 294
   integer :: n_points = nx_global*ny_global
   integer :: ncid, varid
   real(kind=8) :: lon(nx_global,ny_global), lat(nx_global,ny_global)
   integer :: ll_i, ll_j
   real(kind=8) :: dp_conv

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)
   print '(A,I0)', "sender-apple: Component ID: ", comp_id

   call oasis_get_localcomm(local_comm, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_localcomm: ", rcode=kinfo)

   call mpi_comm_size(local_comm, comm_size, kinfo)
   call mpi_comm_rank(local_comm, comm_rank, kinfo)

   kinfo = nf90_open('grids.nc',NF90_NOWRITE,ncid)
   kinfo = nf90_inq_varid(ncid,'nogt.lon',varid)
   kinfo = nf90_get_var(ncid,varid,lon)
   kinfo = nf90_inq_varid(ncid,'nogt.lat',varid)
   kinfo = nf90_get_var(ncid,varid,lat)
   kinfo = nf90_close(ncid)

   local_size=n_points/comm_size
   offset=comm_rank*local_size
   if (comm_rank == comm_size - 1) &
      & local_size = n_points - offset

   part_params(OASIS_Strategy) = OASIS_Apple
   part_params(OASIS_Offset)   = offset
   part_params(OASIS_Length)   = local_size
   call oasis_def_partition(part_id, part_params, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)

   var_nodims=[1, 1]
   print '(A,I0,2A)', "Sender rank(",comm_rank,"): var_name: ", sca_name
   call oasis_def_var(sca_id, sca_name, part_id, var_nodims, OASIS_OUT, &
      &               [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. sca_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   print '(A,I0,2A)', "Sender rank(",comm_rank,"): var_name: ", frc_name
   call oasis_def_var(frc_id, frc_name, part_id, var_nodims, OASIS_OUT, &
      &               [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. frc_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   print '(A,I0,2A)', "Sender rank(",comm_rank,"): var_name: ", nor_name
   call oasis_def_var(nor_id, nor_name, part_id, var_nodims, OASIS_OUT, &
      &               [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. nor_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   dp_conv = atan(1.0)/45.0
   allocate(field(local_size))
   allocate(frac(local_size))
   allocate(scaled(local_size))
   do i = 1, local_size
      ll_j = int((offset+i-1)/nx_global)+1
      ll_i = mod(offset+i-1,nx_global)+1
      field(i) = 2.0 + (sin(lat(ll_i,ll_j)*dp_conv))**3 * &
         & cos(2.*lon(ll_i,ll_j)*dp_conv)
      frac(i) = 1.0 / (1.0 + exp(-0.2*(abs(lat(ll_i,ll_j))- &
         &  60.0 + 10.0 * cos(8.0*lon(ll_i,ll_j)*dp_conv))))
      if (frac(i) <= 1.e-1) frac(i) = 0.0
      if (frac(i) >= 1.0-1.e-1) frac(i) = 1.0
      scaled(i) = field(i) * frac(i)
   end do

   date=0

   call oasis_put(sca_id, date, scaled, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_put: ", rcode=kinfo)

   call oasis_put(frc_id, date, frac, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_put: ", rcode=kinfo)

   call oasis_put(nor_id, date, field, kinfo, fracwgt=frac)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_put: ", rcode=kinfo)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

end program sender_apple
