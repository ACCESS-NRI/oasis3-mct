module def_parallel_decomposition
!
! The global grid is split in npes rectangle partitions with local extent in x = global extent
!
contains
   SUBROUTINE def_local_partition (nlon, nlat, npes, mype, cl_type_src, &
  	     		 il_extentx, il_extenty, il_size, il_offsetx, il_offsety, il_offset)
  IMPLICIT NONE
  INTEGER, INTENT(in)  :: nlon, nlat, npes, mype
  CHARACTER(len=2), INTENT(in)   :: cl_type_src
  INTEGER, INTENT(out) :: il_extentx, il_extenty, il_size, il_offsetx, il_offsety, il_offset
  !
  if (cl_type_src == 'LR') then
     il_extentx = nlon
     il_extenty = nlat/npes ; IF (mype == npes-1)  il_extenty = nlat - (nlat/npes * mype)
     il_size = il_extentx * il_extenty
     il_offsetx = 0
     il_offsety = (nlat/npes * mype)
     il_offset = nlon * il_offsety
  else if (cl_type_src == 'U' .or. cl_type_src == 'D') then
     il_extentx = nlon/npes ; IF (mype == npes-1)  il_extentx = nlon - (nlon/npes * mype)
     il_extenty = nlat
     il_size = il_extentx * il_extenty
     il_offsetx = (nlon/npes * mype)
     il_offsety = 0
     il_offset = nlat * il_offsetx
  endif
  ! 
END SUBROUTINE def_local_partition
!
end module def_parallel_decomposition 
