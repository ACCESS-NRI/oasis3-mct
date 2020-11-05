program writer
   use mod_oasis
   implicit none


   integer :: i, j, kinfo
   integer :: comp_id, part_id
   integer :: part_params(5)
   character(len=13) :: comp_name = "writer"
   integer :: local_comm, comm_size, comm_rank
   integer :: nx_loc = 18, ny_loc = 18
   integer :: nx_global, ny_global
   integer :: ncrn = 4
   real(kind=8), allocatable :: lon(:,:), lat(:,:)
   integer, allocatable :: imsk(:,:)
   real(kind=8), allocatable :: frac(:,:), area(:,:)
   real(kind=8), allocatable :: clo(:,:,:), cla(:,:,:) 
   real(kind=8) :: dx, dy
   
   print '(2A)', "Component name: ", comp_name

   call oasis_init_comp(comp_id, comp_name, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_init_comp: ", rcode=kinfo)

   call oasis_get_localcomm(local_comm, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_get_localcomm: ", rcode=kinfo)

   call mpi_comm_size(local_comm, comm_size, kinfo)
   call mpi_comm_rank(local_comm, comm_rank, kinfo)
   print '(A,I0,A,I0)', "Sender: rank = ",comm_rank, " of ",comm_size

   nx_global = comm_size*nx_loc
   ny_global = ny_loc
   part_params=[2, comm_rank*nx_loc, nx_loc, ny_loc, nx_global]
   call oasis_def_partition(part_id, part_params, kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_def_partition: ", rcode=kinfo)
   
   call oasis_start_grids_writing(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_start_grids_writing: ", rcode=kinfo)
 
   dx = 360/nx_global
   dy = 180/ny_global

   allocate(lon(nx_loc,ny_loc))
   allocate(lat(nx_loc,ny_loc))
   do j = 1, ny_loc
      lon(:,j) = [(comm_rank*nx_loc*dx + real(i)*dx - dx/2, i=1,nx_loc)]
   end do
   do i = 1, nx_loc
      lat(i,:) = [(real(j)*dy - dy/2, j=1,ny_loc)]
   end do
   call oasis_write_grid('pyoa', nx_global, ny_global, lon, lat, part_id)
   
   allocate(clo(nx_loc,ny_loc,ncrn))
   allocate(cla(nx_loc,ny_loc,ncrn))
   do j = 1, ny_loc
      clo(:,j,1) = [(comm_rank*nx_loc*dx + real(i-1)*dx, i=1,nx_loc)]
      clo(:,j,2) = [(comm_rank*nx_loc*dx + real(i)*dx, i=1,nx_loc)]
      clo(:,j,3) = clo(:,j,2)
      clo(:,j,4) = clo(:,j,1)
   end do
   do i = 1, nx_loc
      cla(i,:,1) = [(real(j-1)*dy, j=1,ny_loc)]
      cla(i,:,2) = cla(i,:,1)
      cla(i,:,3) = [(real(j)*dy, j=1,ny_loc)]
      cla(i,:,4) = cla(i,:,3)
   end do
   call oasis_write_corner('pyoa', nx_global, ny_global, ncrn, clo, cla, part_id)

   allocate(imsk(nx_loc,ny_loc))
   imsk(:,:) = 0
   select case(comm_rank)
   case(0)
      imsk(5:6,3:16) = 1
      imsk(7:11,[9,10,15,16]) = 1
      imsk(12,[9,10,11,14,15,16]) = 1
      imsk(13,10:15) = 1
      imsk(14,11:14) = 1
   case(1)
      imsk([4,15],15:16) = 1
      imsk([5,14],13:16) = 1
      imsk([6,13],12:15) = 1
      imsk([7,12],11:13) = 1
      imsk([8,11],10:12) = 1
      imsk(9:10,3:11) = 1
   case(2)
      imsk([5,14],5:14) = 1
      imsk([6,13],4:15) = 1
      imsk([7,12],3:5) = 1
      imsk([7,12],14:16) = 1
      imsk(8:11,3:4) = 1
      imsk(8:11,15:16) = 1
   end select
   call oasis_write_mask('pyoa', nx_global, ny_global, imsk, part_id, companion='STFC')

   allocate(frac(nx_loc,ny_loc))
   frac(:,:) = 1.
   where(imsk == 1) frac = 0.
   call oasis_write_frac('pyoa', nx_global, ny_global, frac, part_id, companion='STFC')

   allocate(area(nx_loc,ny_loc))
   area(:,:) = (3.141592/180.) * abs(sin(cla(:,:,3))-sin(cla(:,:,1))) * &
      & abs(clo(:,:,2)-clo(:,:,1))
   call oasis_write_area('pyoa', nx_global, ny_global, area, part_id)
   
   call oasis_terminate_grids_writing()
   
   call oasis_enddef(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_enddef: ", rcode=kinfo)

   deallocate(lon, lat)
   deallocate(clo, cla)
   deallocate(imsk)
   deallocate(frac, area)
   
   call oasis_terminate(kinfo)
   if(kinfo<0) call oasis_abort(comp_id, comp_name, &
      & "Error in oasis_terminate: ", rcode=kinfo)
   
end program writer
