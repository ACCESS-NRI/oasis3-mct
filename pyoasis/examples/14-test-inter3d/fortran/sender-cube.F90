program sender_cube
   use mpi
   use mod_oasis
   use netcdf
   implicit none
   integer :: i, j, kinfo, date
   integer :: comp_id, partb_id, partc_id, fl1_id, fl2_id, fl3_id, f3d_id
   integer :: partb_params(OASIS_Box_Params), partc_params(OASIS_Cube_Params)
   integer :: local_comm, comm_size, comm_rank, xdec, ydec, idx, idy
   integer :: var_nodims(2)
   character(len=13) :: comp_name = "sender-cube"
   character(len=8) :: fl1_name = "FSENDANA"
   character(len=8) :: fl2_name = "FSENDAN2"
   character(len=8) :: fl3_name = "FSENDAN3"
   character(len=8) :: f3d_name = "FSENDA3D"
   real(kind=8), allocatable :: field(:,:,:)
   integer, parameter :: nx_global = 362, ny_global = 294, nz_global = 3
   integer :: nx, ny
   integer :: ncid, varid
   real(kind=8) :: lon(nx_global,ny_global), lat(nx_global,ny_global)
   integer :: ll_i, ll_j
   real(kind=8) :: dp_conv

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)
   print '(A,I0)', "sender-cube: Component ID: ", comp_id

   call oasis_get_localcomm(local_comm, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_localcomm: ", rcode=kinfo)

   call mpi_comm_size(local_comm, comm_size, kinfo)
   call mpi_comm_rank(local_comm, comm_rank, kinfo)
   do xdec = ceiling(sqrt(real(comm_size))), comm_size
      if (mod(comm_size, xdec) == 0) exit
   end do
   ydec = comm_size / xdec

   kinfo = nf90_open('grids.nc',NF90_NOWRITE,ncid)
   kinfo = nf90_inq_varid(ncid,'nogt.lon',varid)
   kinfo = nf90_get_var(ncid,varid,lon)
   kinfo = nf90_inq_varid(ncid,'nogt.lat',varid)
   kinfo = nf90_get_var(ncid,varid,lat)
   kinfo = nf90_close(ncid)

   nx = ( nx_global / xdec )
   ny = ( ny_global / ydec )

   idx = nx * mod(comm_rank,xdec) + 1
   idy = ny * floor(real(comm_rank)/real(xdec)) + 1

   if ( (idx+nx) > (nx_global+1) ) nx = nx_global-idx+1
   if ( (idy+ny) > (ny_global+1) ) ny = ny_global-idy+1

   partb_params(OASIS_Strategy) = OASIS_Box
   partb_params(OASIS_Offset)   = nx_global * (idy-1) + idx - 1
   partb_params(OASIS_SizeX)    = nx
   partb_params(OASIS_SizeY)    = ny
   partb_params(OASIS_LdX)      = nx_global

   call oasis_def_partition(partb_id, partb_params, kinfo, nx_global*ny_global)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)

   partc_params(OASIS_Strategy) = OASIS_Cube
   partc_params(OASIS_Offset)   = nx_global * (idy-1) + idx - 1
   partc_params(OASIS_SizeX)    = nx
   partc_params(OASIS_SizeY)    = ny
   partc_params(OASIS_LdX)      = nx_global
   partc_params(OASIS_LdY)      = ny_global
   partc_params(OASIS_LdZ)      = nz_global

   call oasis_def_partition(partc_id, partc_params, kinfo, nx_global*ny_global*nz_global)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)

   var_nodims=[1, 1]
   print '(A,I0,2A)', "Sender rank(",comm_rank,"): var_name: ", fl1_name
   call oasis_def_var(fl1_id, fl1_name, partb_id, var_nodims, OASIS_OUT, &
      &               [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. fl1_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   print '(A,I0,2A)', "Sender rank(",comm_rank,"): var_name: ", fl2_name
   call oasis_def_var(fl2_id, fl2_name, partb_id, var_nodims, OASIS_OUT, &
      &               [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. fl2_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   print '(A,I0,2A)', "Sender rank(",comm_rank,"): var_name: ", fl3_name
   call oasis_def_var(fl3_id, fl3_name, partb_id, var_nodims, OASIS_OUT, &
      &               [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. fl3_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   print '(A,I0,2A)', "Sender rank(",comm_rank,"): var_name: ", f3d_name
   call oasis_def_var(f3d_id, f3d_name, partc_id, var_nodims, OASIS_OUT, &
      &               [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. f3d_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   dp_conv = atan(1.0)/45.0
   allocate(field(nx, ny, nz_global))
   do j = 1, ny
      do i = 1, nx
         ll_j = idy + j - 1
         ll_i = idx + i - 1
         field(i,j,1) = 2.0 + (sin(4.*lat(ll_i,ll_j)*dp_conv))**4 * &
            & cos(8.*lon(ll_i,ll_j)*dp_conv)
         field(i,j,2) = 2.0 + (sin(2.*lat(ll_i,ll_j)*dp_conv))**4 * &
            & cos(4.*lon(ll_i,ll_j)*dp_conv)
         field(i,j,3) = 2.0 - cos(atan(1.0)*4.* &
            & (acos(cos(lon(ll_i,ll_j)*dp_conv)*cos(lat(ll_i,ll_j)*dp_conv))/ &
            & (1.2*atan(1.)*4)))
      end do
   end do

   date=0

   call oasis_put(fl1_id, date, field(:,:,1), kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_put: ", rcode=kinfo)

   call oasis_put(fl2_id, date, field(:,:,2), kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_put: ", rcode=kinfo)

   call oasis_put(fl3_id, date, field(:,:,3), kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_put: ", rcode=kinfo)

   call oasis_put(f3d_id, date, field, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_put: ", rcode=kinfo)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

end program sender_cube
