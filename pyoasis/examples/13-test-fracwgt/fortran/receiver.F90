program receiver
   use mpi
   use mod_oasis
   use netcdf
   implicit none
   integer :: i, j, kinfo, date
   integer :: comp_id, part_id, sca_id, frc_id, nor_id
   integer :: part_params(OASIS_Serial_Params)
   integer :: var_nodims(2)
   character(len=8) :: comp_name = "receiver"
   character(len=8) :: sca_name = "FRECVSCA"
   character(len=8) :: frc_name = "FRECVFRC"
   character(len=8) :: nor_name = "FRECVNOR"
   real(kind=8) :: error, epsilon
   integer, parameter :: nx_global = 144, ny_global = 143
   real(kind=8) ::  scaled(nx_global,ny_global)
   real(kind=8) ::  frac(nx_global,ny_global)
   real(kind=8) ::  normalized(nx_global,ny_global)
   integer :: n_points = nx_global*ny_global
   integer :: ncid, varid
   real(kind=8) :: lon(nx_global,ny_global), lat(nx_global,ny_global)
   integer :: imsk(nx_global,ny_global)
   logical :: success

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)
   print '(A,I0)', "receiver: Component ID: ", comp_id

   kinfo = nf90_open('grids.nc',NF90_NOWRITE,ncid)
   kinfo = nf90_inq_varid(ncid,'bggd.lon',varid)
   kinfo = nf90_get_var(ncid,varid,lon)
   kinfo = nf90_inq_varid(ncid,'bggd.lat',varid)
   kinfo = nf90_get_var(ncid,varid,lat)
   kinfo = nf90_close(ncid)

   kinfo = nf90_open('masks.nc',NF90_NOWRITE,ncid)
   kinfo = nf90_inq_varid(ncid,'bggd.msk',varid)
   kinfo = nf90_get_var(ncid,varid,imsk)
   kinfo = nf90_close(ncid)

   part_params(OASIS_Strategy) = OASIS_Serial
   part_params(OASIS_Length)   = n_points
   call oasis_def_partition(part_id, part_params, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)

   var_nodims=[1, 1]
   print '(2A)', "Receiver: var_name: ", sca_name
   call oasis_def_var(sca_id, sca_name, part_id, var_nodims, OASIS_IN, &
      &              [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. sca_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   print '(2A)', "Receiver: var_name: ", frc_name
   call oasis_def_var(frc_id, frc_name, part_id, var_nodims, OASIS_IN, &
      &              [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. frc_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   print '(2A)', "Receiver: var_name: ", nor_name
   call oasis_def_var(nor_id, nor_name, part_id, var_nodims, OASIS_IN, &
      &              [1], OASIS_DOUBLE, kinfo)
   if(kinfo<0 .or. nor_id<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_var: ", rcode=kinfo)

   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   date=0

   scaled(:,:)=0
   frac(:,:)=0
   normalized(:,:)=0

   call oasis_get(sca_id, date, scaled, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get: ", rcode=kinfo)

   call oasis_get(frc_id, date, frac, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get: ", rcode=kinfo)

   call oasis_get(nor_id, date, normalized, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get: ", rcode=kinfo)

   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)

   epsilon=1.e-3

   error=0.
   do j = 1, ny_global
      do i = 1, nx_global
         if (imsk(i,j) == 0 .and. frac(i,j)>0.0) &
            & error = error + abs((normalized(i,j)-(scaled(i,j)/frac(i,j)))/normalized(i,j))
      end do
   end do
   success = error/dble(n_points) < epsilon
   if (success) then
      print '(A,I0,A)',"Receiver: Data field is ok"
   else
      print '(A,I0,A,E12.5)', "Receiver: Error is ",error
   end if

   if(success) print '(A)', "Receiver: Data received successfully"

end program receiver
