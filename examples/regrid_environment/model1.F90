!------------------------------------------------------------------------
! Copyright 2021, CERFACS, Toulouse, France.
! All rights reserved. Use is subject to OASIS3-MCT license terms.
!=============================================================================
!
PROGRAM model1
  !
  USE netcdf
  USE mod_oasis
  USE read_all_data
  USE write_all_fields
  USE function_ana
  USE def_parallel_decomposition
  !
  IMPLICIT NONE
  !
  INCLUDE 'mpif.h'
  !
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double
  !
  CHARACTER(len=30), PARAMETER   :: data_gridname='grids.nc' ! file with the grids
  CHARACTER(len=30), PARAMETER   :: data_maskname='masks.nc' ! file with the masks
  CHARACTER(len=30)              :: data_filename, field_name
  !
  ! Component name (6 characters) same as in the namcouple
  CHARACTER(len=6)   :: comp_name = 'model1'
  CHARACTER(len=128) :: comp_out       ! name of the output log file
  CHARACTER(len=3)   :: chout
  CHARACTER(len=4)   :: cl_grd_src, cl_grd_tgt     ! name of the source grid
  CHARACTER(len=11)  :: cl_remap       ! type of remapping
  CHARACTER(len=2)   :: cl_type_src    ! type of the source grid
  CHARACTER(len=8)   :: cl_period_src  ! periodicity of the source grid (P=periodic or R=regional)
  INTEGER            :: il_overlap_src ! number of overlapping points 
  NAMELIST /grid_source_characteristics/cl_grd_src
  NAMELIST /grid_source_characteristics/cl_remap
  NAMELIST /grid_source_characteristics/cl_type_src
  NAMELIST /grid_source_characteristics/cl_period_src
  NAMELIST /grid_source_characteristics/il_overlap_src
  NAMELIST /grid_target_characteristics/cl_grd_tgt
  !
  ! Grid parameters 
  INTEGER :: il_extentx, il_extenty, il_offsetx, il_offsety
  INTEGER :: il_size, il_offset
  INTEGER :: nlon_atmos, nlat_atmos    ! dimensions in the 2 space directions
  DOUBLE PRECISION, DIMENSION(:,:),   POINTER   :: grid_lon_atmos, grid_lat_atmos ! lon, lat of the cell centers
  INTEGER, DIMENSION(:,:),            POINTER   :: grid_msk_atmos ! mask, 0 == valid point, 1 == masked point
  !
  INTEGER :: mype, npes ! MPI task rank and number
  INTEGER :: local_comm  ! local MPI communicator
  INTEGER :: comp_id    ! component identification
  !
  INTEGER               :: il_part_id
  INTEGER, DIMENSION(3) :: ig_paral
  !
  INTEGER :: ierror, rank, w_unit
  LOGICAL :: file_debug = .true.
  !
  ! Names of exchanged Fields
  CHARACTER(len=8), PARAMETER :: var_name = 'FSENDANA' ! 8 characters field sent
  !
  ! Used in oasis_def_var and oasis_def_var
  INTEGER                       :: var_id
  INTEGER                       :: var_nodims(2) 
  INTEGER                       :: var_type
  !
  ! Grid parameters definition
  INTEGER                       :: var_sh(1) ! not used anymore
  !
  ! Exchanged local fields arrays
  REAL (kind=wp),   POINTER     :: field_send(:,:)
  REAL (kind=wp),   POINTER     :: gradient_i(:,:), gradient_j(:,:), gradient_ij(:,:)
  REAL (kind=wp),   POINTER     :: grad_lat(:,:), grad_lon(:,:)
  !
  !++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  INITIALISATION 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  CALL oasis_init_comp (comp_id, comp_name, ierror )
  IF (ierror /= 0) THEN
      WRITE(0,*) 'oasis_init_comp abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem in oasis_init_comp')
  ENDIF
  !
  ! Unit for output messages : one file for each process
  CALL MPI_Comm_Rank ( MPI_COMM_WORLD, rank, ierror )
  IF (ierror /= 0) THEN
      WRITE(0,*) 'MPI_Comm_Rank abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem in MPI_Comm_Rank')
  ENDIF
  !
  !!!!!!!!!!!!!!!!! OASIS_GET_LOCALCOMM !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  CALL oasis_get_localcomm ( local_comm, ierror )
  IF (ierror /= 0) THEN
      WRITE (0,*) 'oasis_get_localcomm abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem in oasis_get_localcomm')
  ENDIF
  !
  ! Get MPI size and rank
  CALL MPI_Comm_Size ( local_comm, npes, ierror )
  IF (ierror /= 0) THEN
      WRITE(0,*) 'MPI_comm_size abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem in MPI_Comm_Size')
  ENDIF
  !
  CALL MPI_Comm_Rank ( local_comm, mype, ierror )
  IF (ierror /= 0) THEN
      WRITE (0,*) 'MPI_Comm_Rank abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem in MPI_Comm_Rank')
  ENDIF
  !
  IF (file_debug) THEN 
      w_unit = 100 + rank
      WRITE(chout,'(I3)') w_unit
      comp_out=comp_name//'.out_'//chout
      OPEN(w_unit,file=TRIM(comp_out),form='formatted')
  ENDIF
  !
  IF (file_debug) THEN
      WRITE(w_unit,*) '-----------------------------------------------------------'
      WRITE(w_unit,*) TRIM(comp_name), ' running with reals compiled as kind ',wp
      WRITE (w_unit,*) 'I am component ', TRIM(comp_name), ' global rank :',rank
      WRITE(w_unit,*) '----------------------------------------------------------'
      WRITE(w_unit,*) 'I am the ', TRIM(comp_name), ' ', 'component identifier', comp_id, 'local rank', mype
      WRITE (w_unit,*) 'Number of processors :',npes
      WRITE(w_unit,*) '----------------------------------------------------------'
      CALL FLUSH(w_unit)
  ENDIF
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  GRID ACRONYMS and DIMENSIONS
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ !
  !
  ! Get arguments giving source grid acronym and characteristics 
  OPEN(UNIT=70,FILE='name_grids.dat',FORM='FORMATTED')
  READ(UNIT=70,NML=grid_source_characteristics)
  CLOSE(70)
  !
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Source grid name : ',cl_grd_src
      WRITE(w_unit,*) 'Remapping : ',cl_remap
      WRITE(w_unit,*) 'Source grid type : ',cl_type_src
      WRITE(w_unit,*) 'Source grid overlapping pts :',il_overlap_src
      CALL flush(w_unit)
  ENDIF
  !
  ! Read dimensions of the global grid
  CALL read_dimgrid(nlon_atmos, nlat_atmos, cl_grd_src, w_unit, file_debug)
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  PARTITION DEFINITION
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ !
  !
  ! Definition of the local partition
  WRITE(w_unit,*) 'cl_type_src = ', cl_type_src
  call flush(w_unit)
  call def_local_partition(nlon_atmos, nlat_atmos, npes, mype, cl_type_src, &
                         il_extentx, il_extenty, il_size, il_offsetx, il_offsety, il_offset)
  WRITE(w_unit,*) 'Local partition definition'
  WRITE(w_unit,*) 'il_extentx, il_extenty, il_size, il_offsetx, il_offsety, il_offset = ', &
                   il_extentx, il_extenty, il_size, il_offsetx, il_offsety, il_offset
  call flush(w_unit)
  !
  ! APPLE PARTITION
  ig_paral(1) = 1
  ig_paral(2) = il_offset
  ig_paral(3) = il_size
  !
  WRITE(w_unit,*) 'ig_paral = ', ig_paral(:)
  call flush(w_unit)
  !
  CALL oasis_def_partition (il_part_id, ig_paral, ierror)
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  GRID DEFINITION
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ! Allocation of local grid arrays
  ALLOCATE(grid_lon_atmos(il_extentx, il_extenty), STAT=ierror )
  ALLOCATE(grid_lat_atmos(il_extentx, il_extenty), STAT=ierror )
  ALLOCATE(grid_msk_atmos(il_extentx, il_extenty), STAT=ierror )
  !
  ! Reading local grid arrays from input file ocean_mesh.nc
  WRITE(w_unit,*) 'Before read_grid, nlon_atmos, nlat_atmos', nlon_atmos, nlat_atmos
  call flush(w_unit)
  
  CALL read_grid(nlon_atmos, nlat_atmos, il_offsetx+1, il_offsety+1, il_extentx, il_extenty, &
                cl_grd_src, w_unit, grid_lon_atmos, grid_lat_atmos, file_debug) 
  WRITE(w_unit,*) 'After read_grid, nlon_atmos, nlat_atmos', nlon_atmos, nlat_atmos
  CALL read_mask(nlon_atmos, nlat_atmos, il_offsetx+1, il_offsety+1, il_extentx, il_extenty, &
                cl_grd_src, w_unit, grid_msk_atmos, file_debug) 
  WRITE(w_unit,*) 'After read_mask, nlon_atmos, nlat_atmos', nlon_atmos, nlat_atmos
  call flush(w_unit)
  !
  IF (file_debug) THEN
      WRITE(w_unit,*) 'After grid and mask reading'
      CALL FLUSH(w_unit)
  ENDIF
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  COUPLING FIELD DECLARATION  
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  var_nodims(1) = 2    ! Rank of the field array is 2 (not used anymore)
  var_nodims(2) = 1    ! Number of bundle fields
  var_sh(1) = 1        ! (not used anymore)
  var_type = OASIS_Real
  !
  ! Declaration of the field associated with the partition
  CALL oasis_def_var (var_id, var_name, il_part_id, &
     var_nodims, OASIS_Out, var_sh, var_type, ierror)
  IF (ierror /= 0) THEN
      WRITE(w_unit,*) 'oasis_def_var abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem in oasis_def_var')
  ENDIF
  IF (file_debug) THEN
      WRITE(w_unit,*) 'After oasis_def_var'
      CALL FLUSH(w_unit)
  ENDIF
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  TERMINATION OF DEFINITION PHASE 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  CALL oasis_enddef ( ierror )
  IF (ierror /= 0) THEN
      WRITE(w_unit,*) 'oasis_enddef abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem in oasis_enddef')
  ENDIF
  IF (file_debug) THEN
      WRITE(w_unit,*) 'After oasis_enddef'
      CALL FLUSH(w_unit)
  ENDIF
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  SEND ARRAYS 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  ! For simplicity, all processes allocate and define the whole global field
  !
  ! Allocate the field sent by model1
  ALLOCATE(field_send(il_extentx, il_extenty), STAT=ierror )
  IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating field1_send'
  !
#ifdef FANA1
  CALL function_ana1(il_extentx, il_extenty, grid_lon_atmos, grid_lat_atmos, field_send)
#elif defined FANA2
  CALL function_ana2(il_extentx, il_extenty, grid_lon_atmos, grid_lat_atmos, field_send)
#elif defined FANA3
  CALL function_vortex(il_extentx, il_extenty, grid_lon_atmos, grid_lat_atmos, field_send)
#endif
  !
#ifdef SCRIPweights
  ! Special treament for bicubic remapping
  IF (cl_remap == 'bicu') THEN
     IF ( trim(cl_type_src) == 'LR') THEN
        call flush (w_unit)
        ! Calculate the gradients in i, j and ij needed for the bicubic remapping for LR grids
        ! For simplicity, all processes calculate gradients on the whole grid
        ALLOCATE(gradient_i(il_extentx,il_extenty), STAT=ierror )
        IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating gradient_i'
        call flush (w_unit)
        ALLOCATE(gradient_j(il_extentx,il_extenty), STAT=ierror )
        IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating gradient_j'
        call flush (w_unit)
        ALLOCATE(gradient_ij(il_extentx,il_extenty), STAT=ierror )
        IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating gradient_ij'
        call flush (w_unit)
        WRITE(w_unit,*) 'After allocate gradients'
        call flush (w_unit)
        IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating gradient_ij'
        call gradient_bicubic(nlon_atmos, nlat_atmos, il_offsetx+1, il_offsety+1, il_extentx, il_extenty, &
                                  cl_grd_src, il_overlap_src, cl_period_src, w_unit,  &
                                  gradient_i, gradient_j, gradient_ij, file_debug)
        WRITE(w_unit,*) 'After gradient_bicubic'
        call flush (w_unit)
        IF (file_debug) THEN
           WRITE(w_unit,*) 'Bicubic_gradient calculated '
           CALL FLUSH(w_unit)
        ENDIF
        ! Send the local part of the coupling field and gradients 
        call oasis_put(var_id, 0, field_send, ierror, &
                       gradient_i, gradient_j, gradient_ij)
     ELSE IF ( trim(cl_type_src) == 'D') THEN
        ! For Gaussian Reduced grids, a 16-point algorithm is used so gradients
        ! are not needed; send only the local part of the coupling field
        call oasis_put(var_id, 0, field_send, ierror)
     ELSE
        ! Bicubic remapping is not possible for othe grid types
        WRITE(w_unit,*) 'Cannot perform bicubic interpolation for type of grid ',cl_type_src
        CALL oasis_abort(comp_id,comp_name,'Bicubic interpolation impossible for that grid')
     ENDIF
  !
  ! Special treament for 2nd order conservative remapping
  ELSE IF (cl_remap == 'conserv2nd') THEN
     IF ( trim(cl_type_src) == 'LR') THEN
        ! Calculate the gradients in lat and lon directions needed for 2nd order
        ! conservative remapping for LR grids
        ! For simplicity, all processes calculate gradients on the whole grid
        ALLOCATE(grad_lat(il_extentx,il_extenty), STAT=ierror )
        IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating gradient_i'
        ALLOCATE(grad_lon(il_extentx,il_extenty), STAT=ierror )
        IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating gradient_j'
        call gradient_conserv(nlon_atmos, nlat_atmos, il_offsetx+1, il_offsety+1, il_extentx, il_extenty, &
                                  cl_grd_src, il_overlap_src, cl_period_src, w_unit,  &
                                  grad_lon, grad_lat, file_debug)
        IF (file_debug) THEN
           WRITE(w_unit,*) 'Conservative gradient calculated '
           CALL FLUSH(w_unit)
        ENDIF
        grad_lon=0.0
        grad_lat=0.0
        ! Send the local part of the coupling field and gradients
        call oasis_put(var_id, 0, field_send, ierror, &
                       grad_lat, grad_lon)
     ELSE
        ! 2nd order conservative not implemented for grids other than LR
        WRITE(w_unit,*) 'Cannot perform second order conserv interpolation for type of grid ',cl_type_src
        CALL oasis_abort(comp_id,comp_name,'Second order conserv interpolation impossible for that grid')
     ENDIF
  ! Standard oasis_put for other types of remappings
  ELSE
     call oasis_put(var_id, 0, field_send, ierror)
  ENDIF
#elif defined ESMFweights
!  call oasis_put(var_id, 0, field_send(:,:),(/var_sh(2),var_sh(4)/), ierror)
  call oasis_put(var_id, 0, field_send, ierror)
#endif
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !         TERMINATION 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  IF (file_debug) THEN
      WRITE(w_unit,*) 'End of the program, before oasis_terminate'
      CALL FLUSH(w_unit)
  ENDIF
  !
  CALL oasis_terminate (ierror)
  IF (ierror /= 0) THEN
      WRITE(w_unit,*) 'oasis_terminate abort by model1 compid ',comp_id
  ENDIF
  !
  !
END PROGRAM MODEL1
!
