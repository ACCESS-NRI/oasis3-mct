MODULE read_all_data
  !
  USE netcdf
  IMPLICIT NONE
  !
  !
  CONTAINS
!****************************************************************************************
SUBROUTINE read_dimgrid(nlon, nlat, data_filename, cl_grd, w_unit, FILE_Debug)
  !**************************************************************************************
  !
  INTEGER, INTENT(in)               :: w_unit, FILE_Debug
  CHARACTER(len=*), INTENT(in)      :: data_filename
  CHARACTER(len=4)                  :: cl_grd ! name of the grid
  !               
  INTEGER, INTENT(out)       :: nlon, nlat
  !
  ! Local variables to the routine
  INTEGER                  :: il_file_id, il_lon_id, &
                              il_lat_id, &
                              lon_dims, lat_dims

  INTEGER, DIMENSION(NF90_MAX_VAR_DIMS) :: lon_dims_ids, lat_dims_ids, &
                                           lon_dims_len, lat_dims_len

  logical                    :: exists
  INTEGER                    :: i  
  CHARACTER(len=8)           :: cl_nam ! cl_grd+.lon,+.lat ...
  character(len=*),parameter :: subname = '(read_dimgrid)'
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'Data_filename :',TRIM(data_filename)
      CALL FLUSH(w_unit)
  ENDIF
  !
  ! Dimensions
  !
  ! Check if file exists before open it
  inquire(file=TRIM(data_filename),exist=exists)
  if (exists .eqv. .FALSE. ) then
     write(w_unit,*) 'File ',trim(data_filename),' does not exists'
     call routine_model_abort(w_unit,__FILE__,__LINE__,subname)
  endif

  CALL hdlerr(NF90_OPEN(TRIM(data_filename), NF90_NOWRITE, il_file_id), w_unit, subname, __FILE__,__LINE__ )
  !
  cl_nam=TRIM(cl_grd)//".lon" 
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'Longitudes :',TRIM(cl_nam)
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_file_id, TRIM(cl_nam),  il_lon_id), w_unit, subname, __FILE__, __LINE__ )

  CALL hdlerr( NF90_INQUIRE_VARIABLE(il_file_id, varid=il_lon_id, ndims=lon_dims, dimids=lon_dims_ids), w_unit, subname, __FILE__, __LINE__ )
  !
  ! The value lon_dims_len(i) is obtained thanks to the lon_dims_ids ID already obtained from the file
  DO i=1,lon_dims
    CALL hdlerr( NF90_INQUIRE_DIMENSION(ncid=il_file_id,dimid=lon_dims_ids(i),len=lon_dims_len(i)), w_unit, subname, __FILE__, __LINE__ )
  ENDDO
  !
  nlon=lon_dims_len(1)
  nlat=lon_dims_len(2)
  !++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  cl_nam=TRIM(cl_grd)//".lat" 
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'Latitudes :',TRIM(cl_nam)
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_file_id, TRIM(cl_nam),  il_lat_id), w_unit, subname, __FILE__,   __LINE__ )
  !
  CALL hdlerr( NF90_INQUIRE_VARIABLE(ncid=il_file_id, varid=il_lat_id, ndims=lat_dims, dimids=lat_dims_ids), w_unit, subname, __FILE__, __LINE__ )
  !
  ! The value lat_dims_len(i) is obtained thanks to the lat_dims_ids ID already obtained from the file
  DO i=1,lat_dims
    CALL hdlerr( NF90_INQUIRE_DIMENSION(ncid=il_file_id,dimid=lat_dims_ids(i),len=lat_dims_len(i)), w_unit, subname, __FILE__, __LINE__ )
  ENDDO
  !
  IF ( (lat_dims_len(1) .NE. lon_dims_len(1)).OR.(lat_dims_len(2) .NE. lon_dims_len(2)) ) THEN
      WRITE(w_unit,*) 'Problem model1 in read_dimgrid'
      WRITE(w_unit,*) 'Dimensions of the latitude are not the same as the ones of the longitude'
      CALL flush(w_unit)
      STOP
  ENDIF
  !
  CALL hdlerr(NF90_CLOSE(il_file_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'Reading input file ',TRIM(data_filename)
      WRITE(w_unit,*) 'Global dimensions nlon= ',nlon,' nlat= ',nlat
      CALL FLUSH(w_unit)
  ENDIF
  !
  !
END SUBROUTINE read_dimgrid

  !****************************************************************************************
  SUBROUTINE read_grid(nlon, nlat, id_begi, id_begj, id_lon, id_lat, &
                        cl_grd, data_filename, w_unit, FILE_Debug,  &
                        dda_lon, dda_lat)
  !**************************************************************************************
  !
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double
  !
  INTEGER, INTENT(in)            :: w_unit, FILE_Debug                                    
  INTEGER, INTENT(in)            :: nlon, nlat, id_begi, id_begj, id_lon, id_lat
  CHARACTER(len=*), INTENT(in)   :: data_filename
  CHARACTER(len=*), INTENT(in)   :: cl_grd ! name of the grid
  !
  REAL (kind=wp), DIMENSION(id_lon, id_lat), INTENT(out)  :: dda_lon, dda_lat
  !
  ! Local variables to the routine
  CHARACTER(len=8)           :: cl_nam ! cl_grd+.lon,+.lat ...
  character(len=*),parameter :: subname = '(read_grid)'
  logical                    :: exists
  INTEGER                    :: il_file_id, il_lon_id, il_lat_id  
  INTEGER,  DIMENSION(2)     :: ila_dim
  INTEGER,  DIMENSION(2)     :: ila_st
  !
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'Data_filename :',data_filename
      CALL FLUSH(w_unit)
  ENDIF
  !
  ! Check if file exists before open it
  inquire(file=TRIM(data_filename),exist=exists)
  if (exists .eqv. .FALSE. ) then
     write(w_unit,*) 'File ',TRIM(data_filename),' does not exists'
     call routine_model_abort(w_unit,__FILE__,__LINE__,subname)
  endif

  CALL hdlerr(NF90_OPEN(TRIM(data_filename), NF90_NOWRITE, il_file_id), w_unit, subname, __FILE__,__LINE__ )
  !
  cl_nam=TRIM(cl_grd)//".lon" 
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'Longitudes :',TRIM(cl_nam)
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_file_id, TRIM(cl_nam),  il_lon_id),  w_unit, subname, __FILE__, __LINE__ )

  cl_nam=TRIM(cl_grd)//".lat" 
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'Latitudes :',TRIM(cl_nam)
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_file_id, TRIM(cl_nam),  il_lat_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  ila_st(1) = id_begi
  ila_st(2) = id_begj
  !
  ila_dim(1) = id_lon
  ila_dim(2) = id_lat
  !
  ! Data
  !
  CALL hdlerr( NF90_GET_VAR (il_file_id, il_lon_id, dda_lon, &
     ila_st, ila_dim),  w_unit, subname, __FILE__, __LINE__ )
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) '... local grid longitudes reading done'
      CALL FLUSH(w_unit)
  ENDIF
  !
  CALL hdlerr( NF90_GET_VAR (il_file_id, il_lat_id, dda_lat, &
     ila_st, ila_dim),  w_unit, subname, __FILE__, __LINE__ )
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) '... local grid latitudes reading done'
      CALL FLUSH(w_unit)
  ENDIF
  !
  !
  CALL hdlerr( NF90_CLOSE(il_file_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'End of routine read_grid'
      CALL FLUSH(w_unit)
  ENDIF
  !
END SUBROUTINE read_grid

!****************************************************************************************
LOGICAL FUNCTION inquire_mask(cl_grd, data_filename, w_unit, FILE_Debug)
!**************************************************************************************
   !
   INTEGER, INTENT(in)           :: w_unit, FILE_Debug         
   CHARACTER(len=*), INTENT(in)  :: data_filename
   CHARACTER(len=*), INTENT(in)  :: cl_grd ! name of the source grid

   ! local variables to the routine
   CHARACTER(len=8)          :: cl_nam ! cl_grd+.msk
   character(len=*),parameter :: subname = '(inquire_mask)'
   INTEGER                    :: il_file_id, il_msk_id
   logical                    :: exists  
   !
   ! Check if file exists before open it
   inquire(file=TRIM(data_filename),exist=exists)
   if (exists .eqv. .FALSE. ) then
      write(w_unit,*) 'File ',TRIM(data_filename),' does not exists'
      call routine_model_abort(w_unit,__FILE__,__LINE__,subname)
   endif

   CALL hdlerr(NF90_OPEN(data_filename, NF90_NOWRITE, il_file_id), w_unit, subname, __FILE__,__LINE__ )
   !
   !
   cl_nam=TRIM(cl_grd)//".msk" 
   inquire_mask =  NF90_INQ_VARID(il_file_id, TRIM(cl_nam),  il_msk_id) == NF90_NOERR
   !
   CALL hdlerr( NF90_CLOSE(il_file_id),  w_unit, subname, __FILE__, __LINE__ )
   !
   IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'End of function inquire_mask for ',TRIM(cl_grd)
      CALL FLUSH(w_unit)
   ENDIF
   !
END FUNCTION inquire_mask

!****************************************************************************************
LOGICAL FUNCTION inquire_frac(cl_grd, data_filename, w_unit, FILE_Debug)
!**************************************************************************************
   !
   INTEGER, INTENT(in)           :: w_unit, FILE_Debug         
   CHARACTER(len=*), INTENT(in)  :: data_filename
   CHARACTER(len=*), INTENT(in)  :: cl_grd ! name of the source grid

   ! local variables to the routine
   CHARACTER(len=8)          :: cl_nam ! cl_grd+.frc
   character(len=*),parameter :: subname = '(inquire_mask)'
   INTEGER                    :: il_file_id, il_frc_id
   logical                    :: exists  
   !
   ! Check if file exists before open it
   inquire(file=TRIM(data_filename),exist=exists)
   if (exists .eqv. .FALSE. ) then
      write(w_unit,*) 'File ',TRIM(data_filename),' does not exists'
      call routine_model_abort(w_unit,__FILE__,__LINE__,subname)
   endif

   CALL hdlerr(NF90_OPEN(data_filename, NF90_NOWRITE, il_file_id), w_unit, subname, __FILE__,__LINE__ )
   !
   !
   cl_nam=TRIM(cl_grd)//".frc" 
   inquire_frac =  NF90_INQ_VARID(il_file_id, TRIM(cl_nam),  il_frc_id) == NF90_NOERR
   !
   CALL hdlerr( NF90_CLOSE(il_file_id),  w_unit, subname, __FILE__, __LINE__ )
   !
   IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'End of function inquire_frac for ',TRIM(cl_grd)
      CALL FLUSH(w_unit)
   ENDIF
   !
END FUNCTION inquire_frac

  !****************************************************************************************
  SUBROUTINE read_mask(nlon, nlat, id_begi, id_begj, id_lon, id_lat, &
                        cl_grd, data_filename, w_unit, FILE_Debug,  &
                        ida_msk)
  !**************************************************************************************
  !
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double
  !
  INTEGER, INTENT(in)            :: w_unit, FILE_Debug                                    
  INTEGER, INTENT(in)            :: nlon, nlat, id_begi, id_begj, id_lon, id_lat
  CHARACTER(len=*), INTENT(in)   :: data_filename
  CHARACTER(len=*), INTENT(in)   :: cl_grd ! name of the grid
  !
  INTEGER, DIMENSION(id_lon, id_lat), INTENT(out)      :: ida_msk
  !REAL (kind=wp), DIMENSION(id_lon, id_lat), optional  :: ida_frc
  !
  ! Local variables to the routine
  CHARACTER(len=8)           :: cl_nam ! cl_grd+.lon,+.lat ...
  character(len=*),parameter :: subname = '(read_mask)'
  logical                    :: exists, frc_exists
  INTEGER                    :: il_file_id, il_msk_id
  INTEGER,  DIMENSION(2)     :: ila_dim
  INTEGER,  DIMENSION(2)     :: ila_st
  !
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'Data_filename :',TRIM(data_filename)
      CALL FLUSH(w_unit)
  ENDIF
  !
  ! Check if file exists before open it
  inquire(file=TRIM(data_filename),exist=exists)
  if (exists .eqv. .FALSE. ) then
     write(w_unit,*) 'File ',TRIM(data_filename),' does not exists'
     call routine_model_abort(w_unit,__FILE__,__LINE__,subname)
  endif

  CALL hdlerr(NF90_OPEN(data_filename, NF90_NOWRITE, il_file_id), w_unit, subname, __FILE__,__LINE__ )
  !
  !
  cl_nam=TRIM(cl_grd)//".msk" 
  CALL hdlerr( NF90_INQ_VARID(il_file_id, TRIM(cl_nam),  il_msk_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  ila_st(1) = id_begi
  ila_st(2) = id_begj
  !
  ila_dim(1) = id_lon
  ila_dim(2) = id_lat
  !
  ! Data
  !
  CALL hdlerr( NF90_GET_VAR (il_file_id, il_msk_id, ida_msk, &
     ila_st, ila_dim),  w_unit, subname, __FILE__, __LINE__ )
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) '... local mask reading done'
      CALL FLUSH(w_unit)
  ENDIF
  !
  !
  CALL hdlerr( NF90_CLOSE(il_file_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'End of routine read_mask and eventually fraction of mask over ocean'
      CALL FLUSH(w_unit)
  ENDIF
  !
END SUBROUTINE read_mask

  !****************************************************************************************
  SUBROUTINE read_frac(nlon, nlat, id_begi, id_begj, id_lon, id_lat, &
                        cl_grd, data_filename, w_unit, FILE_Debug,  &
                        dda_frc)
  !****************************************************************************************
  !
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double
  !
  INTEGER, INTENT(in)            :: w_unit, FILE_Debug                                    
  INTEGER, INTENT(in)            :: nlon, nlat, id_begi, id_begj, id_lon, id_lat
  CHARACTER(len=*), INTENT(in)   :: data_filename  ! masks.nc
  CHARACTER(len=*), INTENT(in)   :: cl_grd ! name of the grid
  !
  REAL (kind=wp), DIMENSION(id_lon, id_lat), INTENT(out)  :: dda_frc
  !
  ! Local variables to the routine
  CHARACTER(len=8)           :: cl_nam ! cl_grd+.frc
  character(len=*),parameter :: subname = '(read_frac)'
  logical                    :: exists
  INTEGER                    :: il_file_id, il_frc_id  
  INTEGER,  DIMENSION(2)     :: ila_dim
  INTEGER,  DIMENSION(2)     :: ila_st
  !
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'Data_filename :',TRIM(data_filename)
      CALL FLUSH(w_unit)
  ENDIF
  !
  !
  ! Check if file exists before open it
  inquire(file=TRIM(data_filename),exist=exists)
  if (exists .eqv. .FALSE. ) then
     write(w_unit,*) 'File ',TRIM(data_filename),' does not exists'
     call routine_model_abort(w_unit,__FILE__,__LINE__,subname)
  endif

  CALL hdlerr(NF90_OPEN(TRIM(data_filename), NF90_NOWRITE, il_file_id), w_unit, subname, __FILE__,__LINE__ )
  !
  cl_nam=TRIM(cl_grd)//".frc" 
  CALL hdlerr( NF90_INQ_VARID(il_file_id, TRIM(cl_nam), il_frc_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  ila_st(1) = id_begi
  ila_st(2) = id_begj
  !
  ila_dim(1) = id_lon
  ila_dim(2) = id_lat
  !
  ! Data
  !
  CALL hdlerr( NF90_GET_VAR (il_file_id, il_frc_id, dda_frc, &
     ila_st, ila_dim),  w_unit, subname, __FILE__, __LINE__ )
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) '... local area reading done'
      CALL FLUSH(w_unit)
  ENDIF
  !
  CALL hdlerr( NF90_CLOSE(il_file_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'End of routine read_frac'
      CALL FLUSH(w_unit)
  ENDIF
  !
END SUBROUTINE read_frac

  !****************************************************************************************
  SUBROUTINE read_area (nlon, nlat, id_begi, id_begj, id_lon, id_lat, &
                        cl_grd, data_filename, w_unit, FILE_Debug,  &
                        dda_srf)
  !****************************************************************************************
  !
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double
  !
  INTEGER, INTENT(in)            :: w_unit, FILE_Debug                                    
  INTEGER, INTENT(in)            :: nlon, nlat, id_begi, id_begj, id_lon, id_lat
  CHARACTER(len=*), INTENT(in)   :: data_filename
  CHARACTER(len=*), INTENT(in)   :: cl_grd ! name of the grid
  !
  REAL (kind=wp), DIMENSION(id_lon, id_lat), INTENT(out)  :: dda_srf
  !
  ! Local variables to the routine
  CHARACTER(len=8)           :: cl_nam ! cl_grd+.srf
  character(len=*),parameter :: subname = '(read_area)'
  logical                    :: exists
  INTEGER                    :: il_file_id, il_srf_id  
  INTEGER,  DIMENSION(2)     :: ila_dim
  INTEGER,  DIMENSION(2)     :: ila_st
  !
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'Data_filename :',TRIM(data_filename)
      CALL FLUSH(w_unit)
  ENDIF
  !
  !
  ! Check if file exists before open it
  inquire(file=TRIM(data_filename),exist=exists)
  if (exists .eqv. .FALSE. ) then
     write(w_unit,*) 'File ',TRIM(data_filename),' does not exists'
     call routine_model_abort(w_unit,__FILE__,__LINE__,subname)
  endif

  CALL hdlerr(NF90_OPEN(TRIM(data_filename), NF90_NOWRITE, il_file_id), w_unit, subname, __FILE__,__LINE__ )
  !
  cl_nam=TRIM(cl_grd)//".srf" 
  CALL hdlerr( NF90_INQ_VARID(il_file_id, TRIM(cl_nam), il_srf_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  ila_st(1) = id_begi
  ila_st(2) = id_begj
  !
  ila_dim(1) = id_lon
  ila_dim(2) = id_lat
  !
  ! Data
  !
  CALL hdlerr( NF90_GET_VAR (il_file_id, il_srf_id, dda_srf, &
     ila_st, ila_dim),  w_unit, subname, __FILE__, __LINE__ )
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) '... local area reading done'
      CALL FLUSH(w_unit)
  ENDIF
  !
  CALL hdlerr( NF90_CLOSE(il_file_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  IF (FILE_Debug >= 2) THEN
      WRITE(w_unit,*) 'End of routine read_area'
      CALL FLUSH(w_unit)
  ENDIF
  !
END SUBROUTINE read_area

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
END MODULE read_all_data
