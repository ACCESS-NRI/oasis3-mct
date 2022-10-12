MODULE read_all_data
  !
  USE netcdf
  IMPLICIT NONE
  !
  !
  CONTAINS
!****************************************************************************************
SUBROUTINE read_dimgrid (nlon,nlat,cl_grd,w_unit,file_debug)
  !**************************************************************************************
  USE netcdf
  IMPLICIT NONE
  !
  INTEGER                  :: i,j,k,w_unit
  LOGICAL                  :: file_debug
  !
  INTEGER                  :: il_file_id,il_grid_id,il_lon_id, &
     il_lat_id,il_indice_id, &
     lon_dims,lat_dims,imask_dims
  !
  INTEGER, DIMENSION(NF90_MAX_VAR_DIMS) :: lon_dims_ids,lat_dims_ids,&
     imask_dims_ids,lon_dims_len,&
     lat_dims_len,imask_dims_len  
  !               
  INTEGER, INTENT(out)       :: nlon,nlat
  !
  logical                    :: exists
  CHARACTER(len=4)           :: cl_grd ! name of the source grid
  CHARACTER(len=8)           :: cl_nam ! cl_grd+.lon,+.lat ...
  character(len=*),parameter :: subname = '(read_dimgrid)'
  !
  ! Dimensions
  !
  ! Check if file exists before open it
  inquire(file=trim('grids.nc'),exist=exists)
  if (exists .eqv. .FALSE. ) then
     write(w_unit,*) 'File ',trim('grids.nc'),' does not exists'
     call routine_model_abort(w_unit,__FILE__,__LINE__,subname)
  endif

  CALL hdlerr(NF90_OPEN('grids.nc', NF90_NOWRITE, il_file_id), w_unit, subname, __FILE__,__LINE__ )
  !
  cl_nam=TRIM(cl_grd)//".lon" 
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Longitudes :',cl_nam
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_file_id, cl_nam,  il_lon_id), w_unit, subname, __FILE__, __LINE__ )
  cl_nam=TRIM(cl_grd)//".lat" 
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Latitudes :',cl_nam
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_file_id, cl_nam,  il_lat_id), w_unit, subname, __FILE__,   __LINE__ )

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
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Reading input file grids.nc'
      WRITE(w_unit,*) 'Global dimensions nlon=',nlon,' nlat=',nlat
      CALL FLUSH(w_unit)
  ENDIF
  !
END SUBROUTINE read_dimgrid
  !
  !****************************************************************************************
  SUBROUTINE read_grid (nlon, nlat, id_begi, id_begj, id_lon, id_lat, &
                              cl_grd, w_unit, dda_lon, dda_lat, file_debug)
  !**************************************************************************************
  !
  USE netcdf
  IMPLICIT NONE
  !
  INTEGER, INTENT(in)             :: nlon, nlat, id_begi, id_begj, id_lon, id_lat
  CHARACTER(len=4)                :: cl_grd ! name of the source grid
  CHARACTER(len=8)                :: cl_nam ! cl_grd+.lon,+.lat ... 
  INTEGER, INTENT(in)             :: w_unit
  DOUBLE PRECISION, DIMENSION(id_lon, id_lat), INTENT(out)       :: dda_lon, dda_lat
  LOGICAL, INTENT(in)             :: file_debug
  !
  INTEGER :: il_grids_id
  INTEGER :: il_lon_id, il_lat_id
  !
  INTEGER,  DIMENSION(2)          :: ila_dim, ila_st
  CHARACTER(len=*),PARAMETER :: subname = '(read_grid)'
  !
#define _DEBUG
#ifdef _DEBUG
  WRITE(w_unit,*) 'Starting read_grid'
  CALL flush(w_unit)
#endif
  CALL hdlerr (NF90_OPEN('grids.nc', NF90_NOWRITE, il_grids_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  !**************************************************************************************
  !
  cl_nam=TRIM(cl_grd)//".lon"
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Longitudes :',cl_nam
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_grids_id, cl_nam, il_lon_id), w_unit, subname, __FILE__, __LINE__ )
  !
  cl_nam=TRIM(cl_grd)//".lat"
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Latitudes :',cl_nam
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_grids_id, cl_nam, il_lat_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  IF (file_debug) THEN
      WRITE(w_unit,*) 'il_lon_id, il_lat_id :',il_lon_id, il_lat_id
      CALL FLUSH(w_unit)
  ENDIF
  ila_st(1) = id_begi
  ila_st(2) = id_begj
  !
  ila_dim(1) = id_lon
  ila_dim(2) = id_lat
  !
  IF (file_debug) THEN
      WRITE(w_unit,*) 'ila_st, ila_dim :', ila_st(:), ila_dim(:)
      CALL FLUSH(w_unit)
  ENDIF
  !
  CALL hdlerr( NF90_GET_VAR (il_grids_id, il_lon_id, dda_lon, ila_st, ila_dim),  w_unit, subname, __FILE__, __LINE__ )
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Local grid longitudes read from file'
      CALL flush(w_unit)
  ENDIF
  CALL hdlerr( NF90_GET_VAR (il_grids_id, il_lat_id, dda_lat, ila_st, ila_dim),  w_unit, subname, __FILE__, __LINE__ )
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Local grid latitudes read from file'
      CALL flush(w_unit)
  ENDIF
  !
  CALL hdlerr( NF90_CLOSE(il_grids_id),  w_unit, subname, __FILE__, __LINE__ )
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'End of routine read_grid'
  CALL flush(w_unit)
#endif
  !
END SUBROUTINE read_grid
  !
  !****************************************************************************************
  SUBROUTINE read_corner (nlon, nlat, nc, id_begi, id_begj, id_lon, id_lat, &
                              cl_grd, w_unit, dda_clo, dda_cla, file_debug)
  !**************************************************************************************
  !
  USE netcdf
  IMPLICIT NONE
  !
  INTEGER, INTENT(in)             :: nlon, nlat, nc, id_begi, id_begj, id_lon, id_lat
  CHARACTER(len=4)                :: cl_grd ! name of the source grid
  CHARACTER(len=8)                :: cl_nam ! cl_grd+.lon,+.lat ... 
  INTEGER, INTENT(in)             :: w_unit
  DOUBLE PRECISION, DIMENSION(id_lon, id_lat, nc), INTENT(out)   :: dda_clo, dda_cla
  LOGICAL, INTENT(in)             :: file_debug
  !
  INTEGER :: il_grids_id
  INTEGER :: il_clo_id, il_cla_id
  !
  INTEGER,  DIMENSION(3)          :: ila_dim, ila_st
  CHARACTER(len=*),PARAMETER :: subname = '(read_corner)'
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'Starting read_corner'
  CALL flush(w_unit)
#endif
  CALL hdlerr (NF90_OPEN('grids.nc', NF90_NOWRITE, il_grids_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  !**************************************************************************************
  !
  cl_nam=TRIM(cl_grd)//".clo"
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Corner longitudes :',cl_nam
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_grids_id, cl_nam, il_clo_id),  w_unit, subname, __FILE__, __LINE__ )
  cl_nam=TRIM(cl_grd)//".cla"
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Corner latitudes :',cl_nam
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_grids_id, cl_nam, il_cla_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  CALL flush(w_unit)
  ila_st(1) = id_begi
  ila_st(2) = id_begj
  ila_st(3) = 1
  !
  ila_dim(1) = id_lon
  ila_dim(2) = id_lat
  ila_dim(3) = nc
  !
  CALL hdlerr( NF90_GET_VAR (il_grids_id, il_clo_id, dda_clo, ila_st, ila_dim),  w_unit, subname, __FILE__, __LINE__ )
  CALL hdlerr( NF90_GET_VAR (il_grids_id, il_cla_id, dda_cla, ila_st, ila_dim),  w_unit, subname, __FILE__, __LINE__ )
#ifdef _DEBUG
  WRITE(w_unit,*) 'Local grid corner longitudes and latitudes read from file'
  CALL flush(w_unit)
#endif
  !
  CALL hdlerr( NF90_CLOSE(il_grids_id),  w_unit, subname, __FILE__, __LINE__ )
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'End of routine read_corner'
  CALL flush(w_unit)
#endif
  !
END SUBROUTINE read_corner
  !
  !****************************************************************************************
  SUBROUTINE read_mask (nlon, nlat, id_begi, id_begj, id_lon, id_lat, &
                              cl_grd, w_unit, ida_mask, file_debug) 
  !**************************************************************************************
  !
  USE netcdf
  IMPLICIT NONE
  !
  INTEGER, INTENT(in)             :: nlon, nlat, id_begi, id_begj, id_lon, id_lat
  CHARACTER(len=4)                :: cl_grd ! name of the source grid
  CHARACTER(len=8)                :: cl_nam ! cl_grd+.lon,+.lat ... 
  INTEGER, INTENT(in)             :: w_unit
  INTEGER, DIMENSION(id_lon, id_lat), INTENT(out)                :: ida_mask
  LOGICAL, INTENT(in)             :: file_debug
  !
  INTEGER :: il_masks_id
  INTEGER :: il_msk_id
  !
  INTEGER,  DIMENSION(2)          :: ila_dim, ila_st
  CHARACTER(len=*),PARAMETER :: subname = '(read_mask)'
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'Starting read_mask'
  CALL flush(w_unit)
#endif
  CALL hdlerr (NF90_OPEN('masks.nc', NF90_NOWRITE, il_masks_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  !**************************************************************************************
  !
  cl_nam=TRIM(cl_grd)//".msk"
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Mask :',cl_nam
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_masks_id, cl_nam, il_msk_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  CALL flush(w_unit)
  ila_st(1) = id_begi
  ila_st(2) = id_begj
  !
  ila_dim(1) = id_lon
  ila_dim(2) = id_lat
  !
  CALL hdlerr( NF90_GET_VAR (il_masks_id, il_msk_id, ida_mask, ila_st, ila_dim),  w_unit, subname, __FILE__, __LINE__ )
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'Local mask read from file'
  CALL flush(w_unit)
#endif
  !
  CALL hdlerr( NF90_CLOSE(il_masks_id),  w_unit, subname, __FILE__, __LINE__ )
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'End of routine read_mask'
  CALL flush(w_unit)
#endif
  END SUBROUTINE read_mask
  !
  !****************************************************************************************
  SUBROUTINE read_area (nlon, nlat, id_begi, id_begj, id_lon, id_lat, &
                              cl_grd, w_unit,                       &
                              dda_srf, file_debug)
  !**************************************************************************************
  !
  USE netcdf
  IMPLICIT NONE
  !
  INTEGER, INTENT(in)             :: nlon, nlat, id_begi, id_begj, id_lon, id_lat
  CHARACTER(len=4)                :: cl_grd ! name of the source grid
  CHARACTER(len=8)                :: cl_nam ! cl_grd+.lon,+.lat ... 
  INTEGER, INTENT(in)             :: w_unit
  DOUBLE PRECISION, DIMENSION(id_lon, id_lat), INTENT(out)       :: dda_srf
  LOGICAL, INTENT(in)             :: file_debug
  !
  INTEGER :: il_areas_id
  INTEGER :: il_srf_id
  !
  INTEGER,  DIMENSION(2)          :: ila_dim, ila_st
  CHARACTER(len=*),PARAMETER :: subname = '(read_area)'
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'Starting read_area'
  CALL flush(w_unit)
#endif
  CALL hdlerr (NF90_OPEN('areas.nc', NF90_NOWRITE, il_areas_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  !**************************************************************************************
  !
  cl_nam=TRIM(cl_grd)//".srf"
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Areas :',cl_nam
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_areas_id, cl_nam, il_srf_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  CALL flush(w_unit)
  ila_st(1) = id_begi
  ila_st(2) = id_begj
  !
  ila_dim(1) = id_lon
  ila_dim(2) = id_lat
  !
  CALL hdlerr( NF90_GET_VAR (il_areas_id, il_srf_id, dda_srf, ila_st, ila_dim),  w_unit, subname, __FILE__, __LINE__ )
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'Local grid areas read from file'
  CALL flush(w_unit)
#endif
  !
  CALL hdlerr( NF90_CLOSE(il_areas_id),  w_unit, subname, __FILE__, __LINE__ )
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'End of routine read_area'
  CALL flush(w_unit)
#endif
  END SUBROUTINE read_area
  !
  !****************************************************************************************
  LOGICAL FUNCTION inquire_frac (cl_grd, w_unit, file_debug)
  !**************************************************************************************
  !
  USE netcdf
  IMPLICIT NONE
  !
  CHARACTER(len=4)           :: cl_grd ! name of the grid
  CHARACTER(len=8)           :: cl_nam ! cl_grd+.frc
  INTEGER, INTENT(in)        :: w_unit
  LOGICAL, INTENT(in)        :: file_debug
  !
  INTEGER :: il_masks_id
  INTEGER :: il_frc_id
  !
  CHARACTER(len=*),PARAMETER :: subname = '(inquire_frac)'
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'Starting inquire_frac'
  CALL flush(w_unit)
#endif
  CALL hdlerr (NF90_OPEN('masks.nc', NF90_NOWRITE, il_masks_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  !**************************************************************************************
  !
  cl_nam=TRIM(cl_grd)//".frc"
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Frac :',cl_nam
      CALL FLUSH(w_unit)
  ENDIF
  inquire_frac =  NF90_INQ_VARID(il_masks_id, TRIM(cl_nam),  il_frc_id)  == NF90_NOERR
  !
  CALL flush(w_unit)
  CALL hdlerr( NF90_CLOSE(il_masks_id),  w_unit, subname, __FILE__, __LINE__ )
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'End of function inquire_frac'
  CALL flush(w_unit)
#endif
  !
  END FUNCTION inquire_frac
  !
  !****************************************************************************************
  SUBROUTINE read_frac (nlon, nlat, id_begi, id_begj, id_lon, id_lat, &
                              cl_grd, w_unit, dda_frac, file_debug)
  !**************************************************************************************
  !
  USE netcdf
  IMPLICIT NONE
  !
  INTEGER, INTENT(in)             :: nlon, nlat, id_begi, id_begj, id_lon, id_lat
  CHARACTER(len=4)                :: cl_grd ! name of the grid
  CHARACTER(len=8)                :: cl_nam ! cl_grd+.lon,+.lat ... 
  INTEGER, INTENT(in)             :: w_unit
  DOUBLE PRECISION, DIMENSION(id_lon, id_lat), INTENT(out)    :: dda_frac
  LOGICAL, INTENT(in)             :: file_debug
  !
  INTEGER :: il_masks_id
  INTEGER :: il_frc_id
  !
  INTEGER,  DIMENSION(2)          :: ila_dim, ila_st
  CHARACTER(len=*),PARAMETER :: subname = '(read_frac)'
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'Starting read_frac'
  CALL flush(w_unit)
#endif
  CALL hdlerr (NF90_OPEN('masks.nc', NF90_NOWRITE, il_masks_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  !**************************************************************************************
  !
  cl_nam=TRIM(cl_grd)//".frc"
  IF (file_debug) THEN
      WRITE(w_unit,*) 'Frac :',cl_nam
      CALL FLUSH(w_unit)
  ENDIF
  CALL hdlerr( NF90_INQ_VARID(il_masks_id, cl_nam, il_frc_id),  w_unit, subname, __FILE__, __LINE__ )
  !
  CALL flush(w_unit)
  ila_st(1) = id_begi
  ila_st(2) = id_begj
  !
  ila_dim(1) = id_lon
  ila_dim(2) = id_lat
  !
  CALL hdlerr( NF90_GET_VAR (il_masks_id, il_frc_id, dda_frac, ila_st, ila_dim), w_unit, subname, __FILE__, __LINE__ )
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'Local frac read from file'
  CALL flush(w_unit)
#endif
  !
  CALL hdlerr( NF90_CLOSE(il_masks_id),  w_unit, subname, __FILE__, __LINE__ )
  !
#ifdef _DEBUG
  WRITE(w_unit,*) 'End of routine read_frac'
  CALL flush(w_unit)
#endif
  END SUBROUTINE read_frac
  !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
END MODULE read_all_data
