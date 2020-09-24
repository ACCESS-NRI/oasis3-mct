!------------------------------------------------------------------------
! Copyright 2010, CERFACS, Toulouse, France.
! All rights reserved. Use is subject to OASIS3 license terms.
!=============================================================================
!
!
PROGRAM model2
  !
  ! Use for netCDF library
  USE netcdf
  ! Use for OASIS communication library
  USE mod_oasis
  ! Use to read the grid, mask, area data
  USE read_all_data
  ! Use for the grid partition
  USE def_parallel_decomposition
  !
  IMPLICIT NONE
  !
  INCLUDE 'mpif.h'
  !
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double
  !
  CHARACTER(len=30), PARAMETER   :: data_gridname='grids.nc' ! file with all the grids
  !
  ! Component name
  INTEGER, PARAMETER :: mmod = 3
  CHARACTER(len=7),PARAMETER  :: comp_name(mmod) = &
    (/ 'comp2m2', 'comp3m2', 'comp4m2' /)
  INTEGER,PARAMETER  :: comp_rmin(mmod) = (/ 0, 2, 5 /)
  INTEGER,PARAMETER  :: comp_rmax(mmod) = (/ 1, 4, 5 /)
  INTEGER            :: comp_num
  CHARACTER(len=128) :: comp_out   ! name of the output log file
  INTEGER            :: comp_id    ! component identification
  CHARACTER(len=3)   :: chout
  !
  ! Grid parameters definition
  INTEGER, PARAMETER :: mgrid = 2       ! max of grids on a component
  INTEGER            :: ngrid           ! number of active grids
  INTEGER            :: dpes, dpe        
  INTEGER            :: grid_pmin(mgrid)
  INTEGER            :: grid_pmax(mgrid)
  INTEGER            :: part_id(mgrid)  ! use to connect the partition to the variables
  INTEGER            :: nlon(mgrid), nlat(mgrid)     ! dimensions in the 2 directions of space
  ! Define 3 grids to be able to reproduce exe2 with 2 comp, comp2 and comp3 with
  ! comp3 defined with 2 sub-components. comp4m2 does not coupled
  CHARACTER(len=4)   :: cl_grd_tgt(mgrid)  ! name of the grid
  CHARACTER(len=16)  :: pname
  !
  ! Local grid parameters
  INTEGER :: il_extentx(mgrid), il_extenty(mgrid), il_offsetx(mgrid), il_offsety(mgrid)
  INTEGER :: il_size(mgrid), il_offset(mgrid)
  INTEGER :: il_paral_size   ! To specify decomposition (APPLE = 3, BOX = 5)
  INTEGER, DIMENSION(:), POINTER           :: il_paral ! Decomposition for each proc
  REAL (kind=wp), DIMENSION(:,:), POINTER  :: l_lon,l_lat ! lon, lat of the points
  !
  ! Global rank and pe
  INTEGER :: gmype, gnpes

  ! Local rank and pe
  INTEGER :: mype, npes ! rank and  number of pe
  INTEGER :: localComm  ! local MPI communicator and Initialized
  INTEGER :: icpl
  INTEGER :: subcomm(mgrid)
  !
  INTEGER :: ierror, w_unit
  INTEGER :: i, j, n, nl, ng, sr
  INTEGER :: FILE_Debug=2
  !
  ! Names of exchanged Fields
  ! Used in oasis_def_var and oasis_def_var
  integer, parameter :: mvar = 8
  integer            :: nvar(mgrid) 
  character(len=9)   :: var_name(mvar,mgrid) 
  logical            :: var_out(mvar,mgrid) 
  integer, parameter :: nlev = 5
  integer            :: var_num(mvar,mgrid)
  !
  ! Used in oasis_def_var and oasis_def_var
  INTEGER                      :: var_id(mvar,mgrid) 
  INTEGER                      :: var_nodims(2) 
  INTEGER                      :: var_type
  INTEGER                      :: var_actual_shape(1) ! not used anymore in OASIS3-MCT
  !
  REAL (kind=wp), PARAMETER    :: field_ini = -1. ! initialisation of received fields
  !
  INTEGER                      ::  ib
  INTEGER, PARAMETER           ::  il_nb_time_steps = 6 ! number of time steps
  INTEGER, PARAMETER           ::  delta_t = 3600     ! time step
  REAL (kind=wp), PARAMETER    ::  dp_pi=3.14159265359
  REAL (kind=wp), PARAMETER    ::  dp_length= 1.2*dp_pi
  !
  INTEGER                      ::  itap_sec ! Time used in oasis_put/get
  !
  !
  ! Exchanged local fields arrays
  ! used in routines oasis_put and oasis_get
  REAL (kind=wp)                :: fmin,fmax,fsum
  REAL (kind=wp), POINTER       :: field_b(:,:,:)
  REAL (kind=wp), POINTER       :: field(:,:)
  !
  !++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !   INITIALISATION 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  !!!!!!!!!!!!!!!!! OASIS_INIT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  call MPI_INIT(ierror)
  IF (ierror /= 0) THEN
      WRITE(*,*) 'mpi_init abort by exec model2'
      CALL oasis_abort(1,'model2','Problem at mpi_init line 109')
  ENDIF
  CALL MPI_Comm_Size ( MPI_COMM_WORLD, gnpes, ierror )
  IF (ierror /= 0) THEN
      WRITE(*,*) 'MPI_comm_size abort by exec model2'
      CALL oasis_abort(1,'model2','Problem at line 114')
  ENDIF
  CALL MPI_Comm_Rank ( MPI_COMM_WORLD, gmype, ierror )
  IF (ierror /= 0) THEN
      WRITE(0,*) 'MPI_Comm_Rank abort by exec model2'
      CALL oasis_abort(1,'model2','Problem at line 119')
  ENDIF
  !
  WRITE(*,*) 'exec model2 gmype ',gmype

  ! Define the component as a function of the processes
  comp_num=0
  do n = 1,mmod
    WRITE(*,*) 'exec model2 n gmype comp_rmin(n)',n,gmype,comp_rmin(n)
    WRITE(*,*) 'exec model2 n gmype comp_rmax(n)',n,gmype,comp_rmax(n)
    if (gmype >= comp_rmin(n) .and. gmype <= comp_rmax(n)) then
            comp_num = n
            WRITE(*,*) 'exec model2 dispatch component on proc gmype ',comp_num,gmype
    endif
  enddo
  !
  if (comp_num < 1 .or. comp_num > mmod) then
      WRITE(*,*) 'exec model2 abort by comp_num invalid',comp_num,gmype
      CALL oasis_abort(1,'model2','Problem at line 128')
  endif
  !
  ! comp4m2 and comp2m2 does not couple
  IF ( (comp_num == 3) .or. (comp_num == 1) )THEN
     CALL oasis_init_comp (comp_id, comp_name(comp_num), ierror, coupled=.false. )
     IF (ierror /= 0) THEN
         WRITE(0,*) 'oasis_init_comp abort by model2 compid ',comp_id
         CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 137')
     ENDIF
  ELSE
  CALL oasis_init_comp (comp_id, comp_name(comp_num), ierror )
  IF (ierror /= 0) THEN
      WRITE(0,*) 'oasis_init_comp abort by model2 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 143')
  ENDIF
  !
  !!!!!!!!!!!!!!!!! OASIS_GET_LOCALCOMM !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  ! Local communicator with the tasks with the same comp_name name
  CALL oasis_get_localcomm ( localComm, ierror )
  IF (ierror /= 0) THEN
      WRITE (*,*) 'oasis_get_localcomm abort by model2 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 107')
  ENDIF
  !
  ! Get MPI local size and rank
  CALL MPI_Comm_Size ( localComm, npes, ierror )
  IF (ierror /= 0) THEN
      WRITE(*,*) 'MPI_comm_size abort by model2 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 114')
  ENDIF
  !
  CALL MPI_Comm_Rank ( localComm, mype, ierror )
  IF (ierror /= 0) THEN
      WRITE (*,*) 'MPI_Comm_Rank abort by model2 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 120')
  ENDIF
  !
  IF ((FILE_Debug == 1) .AND. (mype == 0)) FILE_Debug=2
  !
  IF (FILE_Debug <= 1) THEN
      IF (mype == 0) THEN
          w_unit = 100 + gmype
          WRITE(chout,'(I3)') w_unit
          comp_out=comp_name(comp_num)//'.root_'//chout
          OPEN(w_unit,file=TRIM(comp_out),form='formatted')
      ELSE
          w_unit = 15
          comp_out=comp_name(comp_num)//'.notroot'
          OPEN(w_unit,file=TRIM(comp_out),form='formatted',position='append')
      ENDIF
  ELSE
      w_unit = 100 + gmype
      WRITE(chout,'(I3)') w_unit
      comp_out=comp_name(comp_num)//'.out_'//chout
      OPEN(w_unit,file=TRIM(comp_out),form='formatted')
  ENDIF
  !
  IF (FILE_Debug >= 2) THEN
      OPEN(w_unit,file=TRIM(comp_out),form='formatted')
      WRITE (w_unit,*) '-----------------------------------------------------------'
      WRITE (w_unit,*) TRIM(comp_name(comp_num)), ' Running with reals compiled as kind =',wp
      WRITE (w_unit,*) 'I am component ', TRIM(comp_name(comp_num)), ' rank :',gmype
      WRITE (w_unit,*) '----------------------------------------------------------'
      WRITE (w_unit,*) 'I am the', TRIM(comp_name(comp_num)), ' ', 'comp', comp_id, 'local rank', mype
      WRITE (w_unit,*)' localcomm = ',localcomm
      CALL FLUSH(w_unit)
  ENDIF
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ! Define coupling field names and whether they are out or in
  ! on each component and each grid
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  subcomm=0
  ngrid = 2

    ng=1
    grid_pmin(ng) = 0
    grid_pmax(ng) = 1
    icpl = MPI_UNDEFINED
    if (mype >= grid_pmin(ng) .and. mype <= grid_pmax(ng)) icpl = 1
        call MPI_COMM_SPLIT(localcomm, icpl, 1, subcomm(ng), ierror)

        cl_grd_tgt(ng) = "lmdz" ! name of the first grid of comp3

        nvar(ng)=8
        var_name(1,ng) = 'SC3GR1M21'
        var_out(1,ng) = .true.
        var_num(1,ng) = 1 
        var_name(2,ng) = 'SC3GR1M22'
        var_out(2,ng) = .true.
        var_num(2,ng) = 1 
        var_name(3,ng) = 'SC3GR1M23'
        var_out(3,ng) = .true.
        var_num(3,ng) = 1 
        var_name(4,ng) = 'SC3GR1M2B'
        var_out(4,ng) = .true.
        var_num(4,ng) = 5 
        var_name(5,ng) = 'RC3GR1M21'
        var_out(5,ng) = .false.
        var_num(5,ng) = 1 
        var_name(6,ng) = 'RC3GR1M22'
        var_out(6,ng) = .false.
        var_num(6,ng) = 1 
        var_name(7,ng) = 'RC3GR1M23'
        var_out(7,ng) = .false.
        var_num(7,ng) = 1 
        var_name(8,ng) = 'RC3GR1M2B'
        var_out(8,ng) = .false.
        var_num(8,ng) = 5 

    ng=2
    grid_pmin(ng) = 2
    grid_pmax(ng) = 2
    icpl = MPI_UNDEFINED
    if (mype >= grid_pmin(ng) .and. mype <= grid_pmax(ng)) icpl = 1
        call MPI_COMM_SPLIT(localcomm, icpl, 1, subcomm(ng), ierror)

        cl_grd_tgt(ng) = "icos"  ! name of the second grid of comp3
        nvar(ng)=8
        var_name(1,ng) = 'SC3GR2M21'
        var_out(1,ng) = .true.
        var_num(1,ng) = 1 
        var_name(2,ng) = 'SC3GR2M22'
        var_out(2,ng) = .true.
        var_num(2,ng) = 1 
        var_name(3,ng) = 'SC3GR2M23'
        var_out(3,ng) = .true.
        var_num(3,ng) = 1 
        var_name(4,ng) = 'SC3GR2M2B'
        var_out(4,ng) = .true.
        var_num(4,ng) = 5 
        var_name(5,ng) = 'RC3GR2M21'
        var_out(5,ng) = .false.
        var_num(5,ng) = 1 
        var_name(6,ng) = 'RC3GR2M22'
        var_out(6,ng) = .false.
        var_num(6,ng) = 1 
        var_name(7,ng) = 'RC3GR2M23'
        var_out(7,ng) = .false.
        var_num(7,ng) = 1 
        var_name(8,ng) = 'RC3GR2M2B'
        var_out(8,ng) = .false.
        var_num(8,ng) = 5 
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  GRID DEFINITION 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  ! Reading global dimensions of the global grid

  do ng=1,ngrid
    if (mype >= grid_pmin(ng) .and. mype <= grid_pmax(ng)) then
    CALL read_dimgrid(nlon(ng), nlat(ng), TRIM(data_gridname), TRIM(cl_grd_tgt(ng)), w_unit, FILE_Debug)
    IF (FILE_Debug >= 2) THEN
       write(w_unit,*) ' Comp_num : ',comp_num, ' grid : ',TRIM(cl_grd_tgt(ng)),nlon(ng),nlat(ng)
    endif
    endif
  enddo
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  PARTITION DEFINITION
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  ! Definition of the local partition
  il_extentx=0
  il_extenty=0
  il_size=0
  il_offsetx=0
  il_offsety=0
  il_offset=0
  !
  do ng=1,ngrid

  if (mype >= grid_pmin(ng) .and. mype <= grid_pmax(ng)) then
      dpe  = mype - grid_pmin(ng)
      dpes = grid_pmax(ng)-grid_pmin(ng)+1

       if ( TRIM(cl_grd_tgt(ng)) == 'icos' ) then
       ! APPLE partition
       il_paral_size=3
       ALLOCATE(il_paral(il_paral_size))
       il_paral(1)=1
       il_paral(2)=0
       il_paral(3)=nlon(ng)
       il_extentx(ng)=il_paral(3)
       il_extenty(ng)=1 

    else

      call def_local_partition(nlon(ng), nlat(ng), dpes, dpe, &
                              il_extentx(ng), il_extenty(ng), &
                              il_size(ng), il_offsetx(ng), il_offsety(ng), il_offset(ng))
      IF (FILE_Debug >= 2) THEN
         WRITE(w_unit,*) 'Local partition definition for grid : ',TRIM(cl_grd_tgt(ng))
         WRITE(w_unit,*) 'il_extentx, il_extenty, il_size, il_offsetx, il_offsety, il_offset = ', &
                          il_extentx(ng), il_extenty(ng), il_size(ng), il_offsetx(ng), &
                          il_offsety(ng), il_offset(ng)
      ENDIF
  !
     call def_paral_size (il_paral_size)
     ALLOCATE(il_paral(il_paral_size))
       !
     call def_paral (il_offset(ng), il_size(ng), il_extentx(ng), il_extenty(ng), &
                     nlon(ng), il_paral_size, il_paral)

    endif
    ! end grid

     IF (FILE_Debug >= 2) THEN
       WRITE(w_unit,*) 'il_paral for ', TRIM(cl_grd_tgt(ng)), il_paral(:)
       call flush(w_unit)
     ENDIF
  !
     write(pname,'(a,i2.2)') cl_grd_tgt(ng),ng
     CALL oasis_def_partition (part_id(ng), il_paral, ierror,name=TRIM(pname))
     IF (FILE_Debug >= 2) THEN
         WRITE(w_unit,*) 'After oasis_def_partition for grid : ',TRIM(cl_grd_tgt(ng))
         CALL FLUSH(w_unit)
     ENDIF
     DEALLOCATE(il_paral)
     endif
     ! endif mype, grid_pmin,grid_pmax
     enddo
     ! enddo grids
  !
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ! DEFINITION OF THE LOCAL FIELDS  
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  !!!!!!!!!!!!!!! !!!!!!!!! OASIS_DEF_VAR !!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  !  Define transient variables
  !
  var_actual_shape(1) = 1 ! Not used anymore in OASIS3-MCT
  var_type = OASIS_Real
  !
  !
  ! Declaration of the field associated with the partition
  do ng=1,ngrid
  if (mype >= grid_pmin(ng) .and. mype <= grid_pmax(ng)) then
  do n = 1,nvar(ng)
     var_nodims(1) = 1    ! Not used anymore
     var_nodims(2) = var_num(n,ng)    ! number of bundles
     if (var_out(n,ng)) then
        CALL oasis_def_var (var_id(n,ng),TRIM(var_name(n,ng)), part_id(ng), &
           var_nodims, OASIS_Out, var_actual_shape, var_type, ierror)
     else
        CALL oasis_def_var (var_id(n,ng),TRIM(var_name(n,ng)), part_id(ng), &
           var_nodims, OASIS_In, var_actual_shape, var_type, ierror)
     endif
     IF (ierror /= 0) THEN
         WRITE (w_unit,*) 'oasis_def_var abort by '//trim(comp_name(comp_num))//' compid ',comp_id
         CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 325')
     ENDIF
  enddo
  endif
  enddo
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'After oasis_def_var'
      CALL FLUSH(w_unit)
  ENDIF
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !         TERMINATION OF DEFINITION PHASE 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  All processes involved in the coupling must call oasis_enddef; 
  !  here all processes are involved in coupling
  !
  !!!!!!!!!!!!!!!!!! OASIS_ENDDEF !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  CALL oasis_enddef ( ierror )
  IF (ierror /= 0) THEN
      WRITE (w_unit,*) 'oasis_enddef abort by model2 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 256')
  ENDIF
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'After oasis_enddef'
      CALL FLUSH(w_unit)
  ENDIF
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ! SEND AND RECEIVE ARRAYS 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !!!!!!!!!!!!!!!!!!!!!!!!OASIS_PUT/OASIS_GET !!!!!!!!!!!!!!!!!!!!!! 
  !
  ! Time loop
  DO ib=1, il_nb_time_steps
    itap_sec = delta_t * (ib-1) ! Time

    do sr = 1,2     ! send = 1, recv = 2, to make sure there are no deadlocks
    DO ng=1,ngrid
      ! Allocate the local fields sent and received by the components 
      ALLOCATE(field_b(il_extentx(ng), il_extenty(ng), nlev), STAT=ierror )
      IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating field_recv_b, line 307'
      ALLOCATE(field(il_extentx(ng), il_extenty(ng)), STAT=ierror )
      IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating field_recv, line 309'
      ALLOCATE(l_lon(il_extentx(ng), il_extenty(ng)), STAT=ierror )
      IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating l_lon, line 500'
      ALLOCATE(l_lat(il_extentx(ng), il_extenty(ng)), STAT=ierror )
      IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating l_lat, line 502'

      ! Read local grid longitudes, latitudes to calculate analytical function
      CALL read_grid(nlon(ng), nlat(ng), il_offsetx(ng)+1, il_offsety(ng)+1, &
                    il_extentx(ng), il_extenty(ng), &
                    TRIM(cl_grd_tgt(ng)), TRIM(data_gridname), w_unit, FILE_Debug, &
                    l_lon, l_lat)


      IF (FILE_Debug >= 2) THEN
         WRITE(w_unit,*) 'After reading grid : ',TRIM(cl_grd_tgt(ng))
         CALL FLUSH(w_unit)
      ENDIF
    !
    DO n = 1,nvar(ng)
        !
        if (var_id(n,ng) /= -1) then
        ! SENT FIEDLS
        if (sr == 1 .and. var_out(n,ng)) then
           ! 
           ! Send other fields
           IF (TRIM(var_name(n,ng)) /= 'SC3GR1M2B' .AND. &
               TRIM(var_name(n,ng)) /= 'SC3GR2M2B') THEN
              field(:,:) =  ib*(2.-COS(dp_pi*(ACOS(COS(l_lat(:,:)*dp_pi/180.)* &
                            COS(l_lon(:,:)*dp_pi/180.))/dp_length)))
              ! Calculate global min and max on all pes
              if (subcomm(ng) /= MPI_COMM_NULL) CALL flddiag(field(:,:),fmin,fmax,fsum,subcomm(ng),il_extentx, il_extenty)
              if (mype == 0) WRITE(w_unit,12) 'tcx other fields sent ',trim(comp_name(comp_num)),TRIM(var_name(n,ng)),TRIM(cl_grd_tgt(ng))
              if (mype == 0) WRITE(w_unit,10) 'tcx other fields min max ',itap_sec,fmin,fmax,fsum

              if (mype >= grid_pmin(ng) .and. mype <= grid_pmax(ng)) then
              CALL oasis_put(var_id(n,ng),itap_sec, field, ierror)
              IF ( ierror .NE. OASIS_Ok .AND. ierror .LT. OASIS_Sent) THEN
                  WRITE (w_unit,*) 'oasis_put abort by model2 compid ',comp_id
                  CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 305')
              ENDIF
              endif

            ELSEIF (TRIM(var_name(n,ng)) == 'SC3GR1M2B' .OR. &
                    TRIM(var_name(n,ng)) == 'SC3GR2M2B') THEN
              ! Send bundle field
              do nl = 1,var_num(n,ng)
                 field_b(:,:,nl) =  ib*(2.-COS(dp_pi*(ACOS(COS(l_lat(:,:)*dp_pi/180.)* &
                                    COS(l_lon(:,:)*dp_pi/180.))/dp_length)))
                 ! Calculate global min and max on all pes
                 if (subcomm(ng) /= MPI_COMM_NULL) CALL flddiag(field_b(:,:,nl),fmin,fmax,fsum,subcomm(ng),il_extentx, il_extenty)
                 if (mype == 0) WRITE(w_unit,12) 'tcx bundle field sent ',trim(comp_name(comp_num)),TRIM(var_name(n,ng)),TRIM(cl_grd_tgt(ng))
                 if (mype == 0) WRITE(w_unit,11) 'tcx bundle min max : ',itap_sec,nl,fmin,fmax,fsum
              enddo

              if (mype >= grid_pmin(ng) .and. mype <= grid_pmax(ng)) then
              CALL oasis_put(var_id(n,ng),itap_sec, field_b, ierror)
              IF ( ierror .NE. OASIS_Ok .AND. ierror .LT. OASIS_Sent) THEN
                  WRITE (w_unit,*) 'oasis_put abort by model2 compid ',comp_id
                  CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 305')
              ENDIF
              endif
          ENDIF

      ! Receive fields      
      elseif (sr == 2 .and. .not. var_out(n,ng)) then
           field_b=field_ini
           field=field_ini
           ! 
           ! Get other fields
          if (TRIM(var_name(n,ng)) /= 'RC3GR1M2B' .AND. &
              TRIM(var_name(n,ng)) /= 'RC3GR2M2B') THEN
              if (mype >= grid_pmin(ng) .and. mype <= grid_pmax(ng)) then
              CALL oasis_get(var_id(n,ng),itap_sec, field, ierror)
              endif
              ! Calculate global min and max on all pes
               if (subcomm(ng) /= MPI_COMM_NULL) CALL flddiag(field(:,:),fmin,fmax,fsum,subcomm(ng),il_extentx, il_extenty)
               if (mype == 0) WRITE(w_unit,12) 'tcx other fields received ',trim(comp_name(comp_num)),TRIM(var_name(n,ng)),TRIM(cl_grd_tgt(ng))
               if (mype == 0)  WRITE(w_unit,10) 'tcx other fields min max ',itap_sec,fmin,fmax,fsum
               IF ( ierror .NE. OASIS_Ok .AND. ierror .LT. OASIS_Recvd) THEN
                  WRITE (w_unit,*) 'oasis_get abort by model2 compid ',comp_id
                  CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 316')
               ENDIF

          elseif (TRIM(var_name(n,ng)) == 'RC3GR1M2B' .OR. &
                  TRIM(var_name(n,ng)) == 'RC3GR2M2B') THEN

              ! Get bundle fields
              if (mype >= grid_pmin(ng) .and. mype <= grid_pmax(ng)) then
              CALL oasis_get(var_id(n,ng),itap_sec, field_b, ierror)
              endif
              ! Calculate global min and max on all pes
              do nl = 1,var_num(n,ng)
                 if (subcomm(ng) /= MPI_COMM_NULL) CALL flddiag(field_b(:,:,nl),fmin,fmax,fsum,subcomm(ng),il_extentx, il_extenty)
                 if (mype == 0) WRITE(w_unit,12) 'tcx bundle received ',trim(comp_name(comp_num)),TRIM(var_name(n,ng)),TRIM(cl_grd_tgt(ng))
                 if (mype == 0)  WRITE(w_unit,11) 'tcx bundle min max ',itap_sec,nl,fmin,fmax,fsum
              enddo
              IF ( ierror .NE. OASIS_Ok .AND. ierror .LT. OASIS_Recvd) THEN
                  WRITE (w_unit,*) 'oasis_get abort by model2 compid ',comp_id
                  CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 316')
              ENDIF
           ENDIF

         ! endif var_id(n,ng) /= -1
          endif
        ! End var_out       
        endif
    ! Enddo nvar
    ENDDO
    ! Enddo grids
  enddo 
    DEALLOCATE(field_b)
    DEALLOCATE(field)
    DEALLOCATE(l_lon)
    DEALLOCATE(l_lat)
    ! enddo sr
    enddo
    ! End time step
  ENDDO
  !
  IF (FILE_Debug >= 2) THEN
      WRITE (w_unit,*) 'End of the program, after exchanges, before oasis_terminate'
      CALL FLUSH(w_unit)
  ENDIF
  !
10 FORMAT(3X,A,3X,I8,3X,F10.5,3X,F10.5,3X,F20.7)
11 FORMAT(3X,A,3X,I8,3X,I3,3X,F10.5,3X,F10.5,3X,F20.7)
12 FORMAT(3X,A,3X,A,3X,A,3X,A)
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !         TERMINATION 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  !!!!!!!!!!!!!!!!!! OASIS_ENDDEF !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  ! Collective call to terminate the coupling exchanges
  !
  CALL oasis_terminate (ierror)
  IF (ierror /= 0) THEN
      WRITE (w_unit,*) 'oasis_terminate abort by model2 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name(comp_num),'Problem at line 340')
  ENDIF
  !
  ! END condition on comp4m2
  ENDIF
  CALL MPI_Finalize(ierror)
  !
END PROGRAM MODEL2
!
