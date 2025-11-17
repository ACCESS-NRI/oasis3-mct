program receiver
   use mpi
   use mod_oasis
   use netcdf
   implicit none
   integer :: i, j, k, kinfo, date
   integer :: comp_id, part_id, part3_id, fl1_id, fl2_id, fl3_id, f3d_id
   integer :: part_params(OASIS_Serial_Params)
   integer :: var_nodims(2)
   character(len=8) :: comp_name = "receiver"
   character(len=8) :: fl1_name = "FRECVLV1"
   character(len=8) :: fl2_name = "FRECVLV2"
   character(len=8) :: fl3_name = "FRECVLV3"
   character(len=8) :: f3d_name = "FRECVF3D"
   real(kind=8) :: error, epsilon
   integer, parameter :: nx_global = 182, ny_global = 149, nz_global = 3
   real(kind=8) ::  field(nx_global,ny_global,nz_global)
   real(kind=8) ::  field_3d(nx_global,ny_global,nz_global)
   integer :: n_points = nx_global*ny_global
   integer :: n_points_3d = nx_global*ny_global*nz_global
   integer :: ncid, varid
   real(kind=8) :: lon(nx_global,ny_global), lat(nx_global,ny_global)
   integer :: imsk(nx_global,ny_global,nz_global)
   logical :: success

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)
   print '(A,I0)', "receiver: Component ID: ", comp_id

   kinfo = nf90_open('grids.nc',NF90_NOWRITE,ncid)
   kinfo = nf90_inq_varid(ncid,'torc.lon',varid)
   kinfo = nf90_get_var(ncid,varid,lon)
   kinfo = nf90_inq_varid(ncid,'torc.lat',varid)
   kinfo = nf90_get_var(ncid,varid,lat)
   kinfo = nf90_close(ncid)

   kinfo = nf90_open('masks.nc',NF90_NOWRITE,ncid)
   kinfo = nf90_inq_varid(ncid,'torc.msk',varid)
   kinfo = nf90_get_var(ncid,varid,imsk(:,:,1))
   kinfo = nf90_inq_varid(ncid,'tol2.msk',varid)
   kinfo = nf90_get_var(ncid,varid,imsk(:,:,2))
   kinfo = nf90_inq_varid(ncid,'tol3.msk',varid)
   kinfo = nf90_get_var(ncid,varid,imsk(:,:,3))
   kinfo = nf90_close(ncid)

   part_params(OASIS_Strategy) = OASIS_Serial
   part_params(OASIS_Length)   = n_points
   CALL oasis_def_partition(part_id, part_params, kinfo, n_points)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)

   part_params(OASIS_Strategy) = OASIS_Serial
   part_params(OASIS_Length)   = n_points_3d
   CALL oasis_def_partition(part3_id, part_params, kinfo, n_points_3d)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)

   var_nodims=[1, 1]
   print '(2A)', "Receiver: var_name: ", fl1_name
   call oasis_def_var(fl1_id, fl1_name, part_id, var_nodims, OASIS_IN, &
      &              [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. fl1_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   print '(2A)', "Receiver: var_name: ", fl2_name
   call oasis_def_var(fl2_id, fl2_name, part_id, var_nodims, OASIS_IN, &
      &              [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. fl2_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   print '(2A)', "Receiver: var_name: ", fl3_name
   call oasis_def_var(fl3_id, fl3_name, part_id, var_nodims, OASIS_IN, &
      &              [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. fl3_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   print '(2A)', "Receiver: var_name: ", f3d_name
   call oasis_def_var(f3d_id, f3d_name, part3_id, var_nodims, OASIS_IN, &
      &              [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. fl3_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   date=0

   field(:,:,:)=0
   field_3d(:,:,:)=0

   call oasis_get(fl1_id, date, field(:,:,1), kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get: ", rcode=kinfo)

   call oasis_get(fl2_id, date, field(:,:,2), kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get: ", rcode=kinfo)

   call oasis_get(fl3_id, date, field(:,:,3), kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get: ", rcode=kinfo)

   call oasis_get(f3d_id, date, field_3d, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get: ", rcode=kinfo)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

   epsilon=1.e-3

   error=0.
   do k = 1, nz_global
      do j = 1, ny_global
         do i = 1, nx_global
            if (imsk(i,j,k) == 0) &
               & error = error + abs((field_3d(i,j,k)-field(i,j,k))/field(i,j,k))
         end do
      end do
   end do
   success = error/dble(n_points_3d) < epsilon
   if (success) then
      print '(A)',"Receiver: Data field is ok"
   else
      print '(A,E12.5)', "Receiver: Error is ",error
   end if

   if(success) print '(A)', "Receiver: Data received successfully"

end program receiver
