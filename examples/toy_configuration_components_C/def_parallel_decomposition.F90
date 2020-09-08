module def_parallel_decomposition
!
! The global grid is split in npes rectangle partitions with local extent in x = global extent
!
contains
   SUBROUTINE def_local_partition (nlon, nlat, npes, mype, &
  	     		 il_extentx, il_extenty, il_size, il_offsetx, il_offsety, il_offset)
  IMPLICIT NONE
  INTEGER, INTENT(in)  :: nlon, nlat, npes, mype
  INTEGER, INTENT(out) :: il_extentx, il_extenty, il_size, il_offsetx, il_offsety, il_offset
  !
  il_extentx = nlon
  il_extenty = nlat/npes ; IF (mype == npes-1)  il_extenty = nlat - (nlat/npes * mype)
  il_size = il_extentx * il_extenty
  il_offsetx = 0
  il_offsety = (nlat/npes * mype)
  il_offset = nlon * il_offsety
  ! 
END SUBROUTINE def_local_partition
!
SUBROUTINE def_paral_size (il_paral_size)
  IMPLICIT NONE
  INTEGER, INTENT(out) :: il_paral_size  
#ifdef DECOMP_APPLE
  il_paral_size = 3
#elif defined DECOMP_BOX
  il_paral_size = 5
#endif
  ! 
END SUBROUTINE def_paral_size
!
SUBROUTINE def_paral(il_offset, il_size, il_extentx, il_extenty, nlon, il_paral_size, il_paral)
  IMPLICIT NONE
  INTEGER, INTENT(IN) :: il_offset, il_size, il_extentx, il_extenty, nlon, il_paral_size
  INTEGER, INTENT(OUT) :: il_paral(il_paral_size) 
#ifdef DECOMP_APPLE
  il_paral(1) = 1
  il_paral(2) = il_offset
  il_paral(3) = il_size
#elif defined DECOMP_BOX
  il_paral(1) = 2
  il_paral(2) = il_offset
  il_paral(3) = il_extentx
  il_paral(4) = il_extenty
  il_paral(5) = nlon
#endif
  ! 
END SUBROUTINE def_paral
!
SUBROUTINE def_local_partition_ssea_icos (id_paral,id_size,id_im,id_jm,id_rank,id_npes,id_unit)

  IMPLICIT NONE
  INTEGER, DIMENSION(id_size), INTENT(out) :: id_paral(id_size)
  INTEGER, INTENT(in)  :: id_size
  INTEGER, INTENT(in)  :: id_im       ! Grid dimension in i
  INTEGER, INTENT(in)  :: id_jm       ! Grid dimension in j
  INTEGER, INTENT(in)  :: id_rank     ! Rank of process
  INTEGER, INTENT(in)  :: id_npes     ! Number of processes involved in the coupling
  INTEGER, INTENT(in)  :: id_unit     ! Unit of log file
  INTEGER              :: il_imjm, il_partj
  !
  if (id_rank < 0 .or. id_rank > id_npes) then
    write(id_unit,*) 'def_local_partition_ssea ABORT invalid rank',id_rank,id_npes
    stop
  endif
  il_imjm = id_im*id_jm
  il_partj = id_jm/id_npes  ! Nbr of latitude circles in the partition
  !
  ! Each process is responsible for a part of field defined by
  ! the number of grid points and the offset of the first point
  !
  WRITE (id_unit,*) 'APPLE partitioning'
  !
  IF (id_rank .LT. (id_npes-1)) THEN
      id_paral (1) = 1
      id_paral (2) = id_rank*(il_partj * id_im)
      id_paral (3) = il_partj * id_im
  ELSE
      id_paral (1) = 1
      id_paral (2) = id_rank*(il_partj * id_im)
      id_paral (3) = il_imjm-(id_rank*(il_partj * id_im))
  ENDIF
  !
END SUBROUTINE def_local_partition_ssea_icos
end module def_parallel_decomposition 
