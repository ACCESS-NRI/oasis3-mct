PROGRAM oasis_testcase
   USE xios
   USE mod_wait
   USE netcdf
   IMPLICIT NONE
   INCLUDE "mpif.h"
   INTEGER,PARAMETER :: unit=10
   INTEGER,PARAMETER :: len_str=255
   INTEGER :: ierr

   INTEGER :: nb_proc_toy
   CHARACTER(LEN=len_str)  :: start_date
   CHARACTER(LEN=len_str)  :: duration
   NAMELIST /params_run/    nb_proc_toy, duration


   TYPE tmodel_params
      CHARACTER(len_str)  :: grids_file=""
      CHARACTER(len_str)  :: masks_file=""
      CHARACTER(len_str)  :: areas_file=""
      CHARACTER(len_str)  :: timestep=""
      CHARACTER(len_str)  :: domain=""
      LOGICAL             :: is_ocean
      DOUBLE PRECISION    :: domain_proc_frac
      INTEGER             :: domain_proc_n
      CHARACTER(len_str)  :: axis=""
      DOUBLE PRECISION    :: axis_proc_frac
      INTEGER             :: axis_proc_n
      INTEGER             :: ni 
      INTEGER             :: nj 
      CHARACTER(len_str)  :: init_field2D=""
      DOUBLE PRECISION    :: gf_coef
      LOGICAL :: domain_mask
   END TYPE  tmodel_params

   LOGICAL :: i_am_atm, i_am_server
   INTEGER :: rank, size_loc


   OPEN(unit=unit, file='param.def',status='old',iostat=ierr)
   nb_proc_toy=1
   duration="1h"
   start_date="2018-01-01"
   READ (unit, nml=params_run)
   CLOSE(unit)

   ! MPI Initialization

   CALL MPI_INIT(ierr)
   CALL init_wait
   CALL MPI_COMM_RANK(MPI_COMM_WORLD,rank,ierr)
   CALL MPI_COMM_SIZE(MPI_COMM_WORLD,size_loc,ierr)
   IF (size_loc < nb_proc_toy) THEN
      PRINT *,"inconsistency : size=",size_loc," nb_proc_toy=",nb_proc_toy
      CALL MPI_ABORT()
   ENDIF

   i_am_atm=.FALSE. ; i_am_server=.FALSE. 

   ! First ranks are dedicated to Toy last to Server

   IF (rank < nb_proc_toy) THEN 
      i_am_atm=.TRUE. 
   ELSE
      i_am_server=.TRUE. 
   ENDIF;


   IF (i_am_server) THEN
      CALL xios_init_server()  
   ELSE
      IF (i_am_atm) CALL model("toy")
      CALL xios_finalize()
   ENDIF

   WRITE(*,'(A,I0,A)') "Rank ",rank, " finished Successfully"  
   CALL MPI_FINALIZE(ierr)

CONTAINS

   SUBROUTINE model(model_id)
      IMPLICIT NONE
      CHARACTER(LEN=*) :: model_id
      TYPE(tmodel_params) :: params, other_params
      TYPE(xios_context) :: ctx_hdl
      INTEGER :: comm
      TYPE(xios_date)  :: cdate, edate
      TYPE(xios_duration)  :: dtime
      INTEGER :: rank
      INTEGER :: size_loc
      INTEGER :: ts

      DOUBLE PRECISION, POINTER :: lon(:)
      DOUBLE PRECISION, POINTER :: lat(:)
      LOGICAL, POINTER          :: domain_mask(:)
      INTEGER, POINTER          :: domain_index(:)

      DOUBLE PRECISION, POINTER :: field2D_init(:)

      DOUBLE PRECISION, POINTER :: field2D(:), other_field2D(:) 

      INTEGER :: ni,nj
      INTEGER :: i,xy
      INTEGER :: ierr

      LOGICAL :: ok_field2D
      LOGICAL :: ok_other_field2D

      !! XIOS Initialization (get the local communicator)
      CALL xios_initialize(TRIM(model_id),return_comm=comm)
      CALL MPI_COMM_RANK(comm,rank,ierr)
      CALL MPI_COMM_SIZE(comm,size_loc,ierr)
      CALL xios_context_initialize(TRIM(model_id),comm)
      CALL xios_get_handle(TRIM(model_id),ctx_hdl)
      CALL xios_set_current_context(ctx_hdl)

      CALL init_model_params('src_',params)
      CALL init_model_params('tgt_',other_params)

      IF (params%is_ocean .OR. other_params%is_ocean) THEN
         params%domain_mask = .TRUE.
         other_params%domain_mask = .TRUE.
      END IF

     IF (TRIM(params%init_field2D) == "genmask") THEN
        other_params%domain_mask = .FALSE.
        IF (.NOT. params%is_ocean) THEN
           IF (rank == 0) WRITE(*,*) &
              & '====> WARNING: meaningless fractionary mask computation if the source mesh is not oceanic'
        END IF
     END IF
      
!!! Definition de la start date et du timestep
      CALL xios_set_start_date(xios_date_convert_from_string(start_date//" 00:00:00"))
      dtime=xios_duration_convert_from_string(TRIM(params%timestep))
      CALL xios_set_timestep(timestep=dtime)

!!! Calcul de temps elaps par seconde pour respecter le SYPD (hyp : pas de delai d'I/O)
      CALL xios_get_start_date(cdate)
      edate=cdate+xios_duration_convert_from_string(TRIM(duration))

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!             standard initialisation of domain, grid, field                               !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      CALL init_domain("src_domain", comm, params, ni, nj, lon, lat, domain_mask, domain_index)

      CALL init_field2D(comm, params, lon, lat, domain_mask, field2D_init)

      xy=SIZE(domain_index)

      ALLOCATE(field2D(0:xy-1))

      DO i=0,xy-1
         IF (domain_index(i)/=-1) THEN
            field2D(i)=field2D_init(domain_index(i))
         ENDIF
      ENDDO

      ok_field2D=xios_is_valid_field("src_field2D") ;

      IF (ASSOCIATED(lon)) DEALLOCATE(lon)
      IF (ASSOCIATED(lat)) DEALLOCATE(lat)
      IF (ASSOCIATED(domain_mask)) DEALLOCATE(domain_mask)
      IF (ASSOCIATED(domain_index)) DEALLOCATE(domain_index)
      IF (ASSOCIATED(field2D_init)) DEALLOCATE(field2D_init)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      !              duplicated section for other_                    !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      CALL init_domain("tgt_domain", comm, other_params, ni, nj, lon, lat, domain_mask, domain_index)

      CALL init_field2D(comm, other_params, lon, lat, domain_mask, field2D_init)

      xy=SIZE(domain_index)

      ALLOCATE(other_field2D(0:xy-1))

      DO i=0,xy-1
         IF (domain_index(i)/=-1) THEN
            other_field2D(i)=field2D_init(domain_index(i))
         ENDIF
      ENDDO

      ok_other_field2D=xios_is_valid_field("tgt_field2D") ;


!!!!!!!!!!!!!!!!!!!!! end of duplicated section   !!!!!!!!!!!!!!!!!!!!!!!!!!

      ! Conditional setting of the interpolation for the fractionary mask

      IF (TRIM(params%init_field2D) == "genmask") THEN
         CALL xios_set_interpolate_domain_attr("interpolation", &
            & order=1, renormalize=.FALSE., use_area=.FALSE., &
            & detect_missing_value=.FALSE., write_weight=.FALSE.)
      END IF
      
      !

      ts=1
      cdate=cdate+dtime
      CALL xios_close_context_definition()
      CALL xios_set_current_context(TRIM(model_id))


      DO WHILE ( cdate <= edate )

!!! Mise a jour du pas de temps
         CALL xios_update_calendar(ts)

         IF (ok_field2D) CALL xios_send_field("src_field2D",field2D)

         field2D=field2D+1

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
         !              duplicated section for other_                    !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


         IF (ok_other_field2D) CALL xios_send_field("tgt_field2D", other_field2D)
         other_field2D=other_field2D+1


!!!!!!!!!!!!!!!!!!!!!! end of duplicated section !!!!!!!!!!!!!!!!!


         cdate=cdate+dtime
         ts=ts+1
      ENDDO

      CALL xios_context_finalize()
      CALL MPI_COMM_FREE(comm, ierr)

   END SUBROUTINE model

   SUBROUTINE init_model_params(prefix,params)
      IMPLICIT NONE
      CHARACTER(LEN=*) :: prefix
      TYPE(tmodel_params) :: params


      IF (.NOT. xios_getvar(prefix//"timestep", params%timestep) )         params%timestep="1h"
      IF (.NOT. xios_getvar(prefix//"domain", params%domain) )             params%domain="lmdz"
      IF (.NOT. xios_getvar("grids_input_file", params%grids_file) )       params%grids_file="input_data/grids.nc"
      IF (.NOT. xios_getvar("masks_input_file", params%masks_file) )       params%masks_file="input_data/masks.nc"
      IF (.NOT. xios_getvar("areas_input_file", params%areas_file) )       params%areas_file="input_data/areas.nc"
      IF (.NOT. xios_getvar(prefix//"domain_mask", params%domain_mask) )   params%domain_mask=.FALSE.
      IF (.NOT. xios_getvar(prefix//"ni", params%ni) )                     params%ni=36
      IF (.NOT. xios_getvar(prefix//"nj", params%nj) )                     params%nj=18
      IF (.NOT. xios_getvar("init_field2D", params%init_field2D) ) params%init_field2D="academic"
      IF (.NOT. xios_getvar("gulf_stream_coeff", params%gf_coef) ) params%gf_coef=0.0

      IF (.NOT. xios_getvar(prefix//"domain_proc_n", params%domain_proc_n)) params%domain_proc_n=0
      IF (.NOT. xios_getvar(prefix//"axis_proc_n", params%axis_proc_n)) params%axis_proc_n=0
      IF ((.NOT. xios_getvar(prefix//"domain_proc_frac", params%domain_proc_frac)) .AND.  &
         (.NOT. xios_getvar(prefix//"axis_proc_frac", params%axis_proc_frac))) THEN
         params%domain_proc_frac=1.0
         params%axis_proc_frac=0.0
      ELSE IF (.NOT. xios_getvar(prefix//"domain_proc_frac", params%domain_proc_frac)) THEN
         params%domain_proc_frac=0.0
      ELSE IF (.NOT. xios_getvar(prefix//"axis_proc_frac", params%axis_proc_frac)) THEN
         params%axis_proc_frac=0.0
      ENDIF

      SELECT CASE(TRIM(params%domain))
      CASE('torc', 'nogt', 'to25', 't12e' )
         params%is_ocean = .TRUE.
      CASE DEFAULT
         params%is_ocean = .FALSE.
      END SELECT

      params%domain_mask = params%domain_mask .OR. params%is_ocean

   END SUBROUTINE init_model_params


   SUBROUTINE init_domain(domain_id, comm, params, return_ni, return_nj,             &
      return_lon, return_lat, return_mask, return_index)
      IMPLICIT NONE
      CHARACTER(LEN=*),INTENT(IN) :: domain_id
      TYPE(tmodel_params),INTENT(IN) :: params
      INTEGER,INTENT(IN) :: comm
      INTEGER,INTENT(OUT) :: return_ni
      INTEGER,INTENT(OUT) :: return_nj
      DOUBLE PRECISION, POINTER :: return_lon(:)
      DOUBLE PRECISION, POINTER :: return_lat(:)
      LOGICAL, POINTER :: return_mask(:)
      INTEGER, POINTER :: return_index(:)

      SELECT CASE(params%domain)
      CASE("lmdz")
         CALL init_domain_lmdz(domain_id,comm,params, return_ni, return_nj,               &
            return_lon, return_lat, return_mask, return_index)
      CASE("bggd", "tlan")
         CALL init_domain_bggd(domain_id,comm,params, return_ni, return_nj,               &
            return_lon, return_lat, return_mask, return_index)
      CASE("icos", "icoh")
         CALL init_domain_icos(domain_id,comm,params, return_ni, return_nj,               &
            return_lon, return_lat, return_mask, return_index)
      CASE("ssea", "t359", "sse7")
         CALL init_domain_ssea(domain_id,comm,params, return_ni, return_nj,               &
            return_lon, return_lat, return_mask, return_index)
      CASE("gaussian")
         CALL init_domain_gaussian(domain_id,comm,params, return_ni, return_nj,               &
            return_lon, return_lat, return_mask, return_index)
      CASE("nemo")
         CALL init_domain_nemo(domain_id,comm,params, return_ni, return_nj,               &
            return_lon, return_lat, return_mask, return_index)
      CASE("nogt", "torc", "to25", "t12e")
         CALL init_domain_orca(domain_id,comm,params, return_ni, return_nj,               &
            return_lon, return_lat, return_mask, return_index)
      END SELECT

   END SUBROUTINE init_domain

   SUBROUTINE init_field2D(comm, params, lon, lat, mask, return_field)
      IMPLICIT NONE
      INTEGER :: comm
      TYPE(tmodel_params) :: params
      DOUBLE PRECISION, POINTER :: lon(:)
      DOUBLE PRECISION, POINTER :: lat(:)
      LOGICAL, POINTER :: mask(:)
      DOUBLE PRECISION, POINTER :: return_field(:)

      SELECT CASE(params%init_field2D)
      CASE("academic")
         CALL init_field2D_academic(params,lon, lat, mask, return_field)
      CASE("vortex")
         CALL init_field2D_vortex(params,lon, lat, mask, return_field)
      CASE("one")
         CALL init_field2D_one(mask, return_field)
      CASE("rank")
         CALL init_field2D_rank(comm, mask, return_field)
      CASE("genmask")
         CALL init_field2D_mask(comm, mask, return_field)
      END SELECT

   END SUBROUTINE init_field2D


   SUBROUTINE init_domain_gaussian(domain_id, comm, params, return_ni, return_nj,               &
      return_lon,return_lat,return_mask, return_index)
      IMPLICIT NONE 
      CHARACTER(LEN=*) :: domain_id
      TYPE(tmodel_params) :: params
      INTEGER :: comm
      INTEGER :: return_ni
      INTEGER :: return_nj
      DOUBLE PRECISION, POINTER :: return_lon(:)
      DOUBLE PRECISION, POINTER :: return_lat(:)
      LOGICAL, POINTER :: return_mask(:)
      INTEGER, POINTER :: return_index(:)
      INTEGER :: domain_proc_rank, domain_proc_size    

      INTEGER :: mpi_rank, mpi_size
      INTEGER ::  ierr

      INTEGER :: nlon, nlat
      DOUBLE PRECISION,ALLOCATABLE :: lon_glo(:),lat_glo(:)
      DOUBLE PRECISION,ALLOCATABLE :: bounds_lon_glo(:,:),bounds_lat_glo(:,:)
      INTEGER,ALLOCATABLE :: i_index_glo(:)
      INTEGER,ALLOCATABLE :: i_index(:)
      LOGICAL,ALLOCATABLE :: mask_glo(:),mask(:)
      DOUBLE PRECISION,ALLOCATABLE :: lon(:),lat(:),field_A_srf(:,:)
      DOUBLE PRECISION,ALLOCATABLE :: bounds_lon(:,:),bounds_lat(:,:)

      INTEGER :: i,j,n
      INTEGER :: ncell_glo,ncell,ind
      REAL :: ilon,ilat
      DOUBLE PRECISION, PARAMETER :: Pi=3.14159265359
      INTEGER,ALLOCATABLE :: list_ind(:,:)
      INTEGER :: rank,j1,j2,np,ncell_x
      INTEGER :: data_n_index
      INTEGER,ALLOCATABLE :: data_i_index(:)
      INTEGER :: axis_proc_rank, axis_proc_size



      CALL MPI_COMM_RANK(comm,mpi_rank,ierr)
      CALL MPI_COMM_SIZE(comm,mpi_size,ierr)

      CALL get_decomposition(comm, params, domain_proc_size, domain_proc_rank, axis_proc_size, axis_proc_rank)

      mpi_rank=domain_proc_rank
      mpi_size=domain_proc_size
      nlon=params%ni
      nlat=params%nj


      ncell_glo=0
      DO j=1,nlat
         n =  NINT(COS(Pi/2-(j-0.5)*PI/nlat)*nlon)
         IF (n<8) n=8
         ncell_glo=ncell_glo+n
      ENDDO

      ALLOCATE(lon_glo(ncell_glo))
      ALLOCATE(lat_glo(ncell_glo))
      ALLOCATE(bounds_lon_glo(4,ncell_glo))
      ALLOCATE(bounds_lat_glo(4,ncell_glo))
      ALLOCATE(i_index_glo(ncell_glo)) ; i_index_glo(:) = -1
      ALLOCATE(mask_glo(ncell_glo))
      ALLOCATE(list_ind(nlon,nlat))

      ind=0
      DO j=1,nlat
         n = NINT(COS(Pi/2-(j-0.5)*PI/nlat)*nlon)
         IF (mpi_rank == 0 .AND. j==1) PRINT*,"--- Gauss lon at first lat ",n
         IF (mpi_rank == 0 .AND. j==nlat) PRINT*,"--- Gauss lon at last lat  ",n
         IF (n<8) n=8

         DO i=1,n
            ind=ind+1
            list_ind(i,j)=ind
            ilon=i-0.5
            ilat=j-0.5

            lat_glo(ind)= 90-(ilat*180./nlat)
            lon_glo(ind)= (ilon*360./n)-180.


            bounds_lat_glo(1,ind)= 90-((ilat-0.5)*180./nlat)
            bounds_lon_glo(1,ind)=((ilon-0.5)*360./n)-180.

            bounds_lat_glo(2,ind)= 90-((ilat-0.5)*180./nlat)
            bounds_lon_glo(2,ind)=((ilon+0.5)*360./n)-180.

            bounds_lat_glo(3,ind)= 90-((ilat+0.5)*180./nlat)
            bounds_lon_glo(3,ind)=((ilon+0.5)*360./n)-180.

            bounds_lat_glo(4,ind)= 90-((ilat+0.5)*180./nlat)
            bounds_lon_glo(4,ind)=((ilon-0.5)*360./n)-180.

         ENDDO
      ENDDO

      !  mpi_size=32
      rank=(mpi_size-1)/2
      ncell_x=SQRT(ncell_glo*1./mpi_size)

      j1=nlat/2
      DO WHILE(rank>=0)
         j2=MAX(j1-ncell_x+1,1)
         j=(j1+j2)/2
         n=NINT(COS(Pi/2-(j-0.5)*PI/nlat)*nlon)
         IF (n<8) n=8
         np = MIN(n/ncell_x,rank+1) ;
         IF (j2==1) np=rank+1
         IF (np == rank+1) j2 = 1

         IF (mpi_rank == 0 ) PRINT *,"domain ",j2,j1,rank,np ;
         DO j=j2,j1
            n=NINT(COS(Pi/2-(j-0.5)*PI/nlat)*nlon)
            IF (n<8) n=8
            DO i=1,n
               ind=list_ind(i,j)
               IF ( (i-1) < MOD(n,np)*(n/np+1)) THEN  
                  i_index_glo(ind) = rank - (i-1)/(n/np+1)
               ELSE
                  i_index_glo(ind) = rank-(MOD(n,np)+ (i-1-MOD(n,np)*(n/np+1))/(n/np))
               ENDIF
            ENDDO
         ENDDO
         rank=rank-np
         j1=j2-1
      ENDDO

      rank=MIN((mpi_size-1)/2+1, (mpi_size-1))
      ncell_x=SQRT(ncell_glo*1./mpi_size)

      j1=nlat/2+1
      DO WHILE(rank<=mpi_size-1)
         j2=MIN(j1+ncell_x-1,nlat)
         j=(j1+j2)/2
         n=NINT(COS(Pi/2-(j-0.5)*PI/nlat)*nlon)
         IF (n<8) n=8
         np = MIN(n/ncell_x,mpi_size-rank) ;
         IF (j2==nlat) np=mpi_size-rank
         IF (np==mpi_size-rank) j2 = nlat

         IF (mpi_rank == 0 ) PRINT *,"domain ",j2,j1,rank,np ;
         DO j=j1,j2
            n=NINT(COS(Pi/2-(j-0.5)*PI/nlat)*nlon)
            IF (n<8) n=8
            DO i=1,n
               ind=list_ind(i,j)
               IF ( (i-1) < MOD(n,np)*(n/np+1)) THEN
                  i_index_glo(ind) = rank + (i-1)/(n/np+1)
               ELSE
                  i_index_glo(ind) = rank+(MOD(n,np)+ (i-1-MOD(n,np)*(n/np+1))/(n/np))
               ENDIF
            ENDDO
         ENDDO
         rank=rank+np
         j1=j2+1
      ENDDO

      ncell=0
      DO ind=1,ncell_glo
         IF (i_index_glo(ind)==mpi_rank) ncell=ncell+1
      ENDDO
      ALLOCATE(i_index(ncell))
      ALLOCATE(lon(ncell))
      ALLOCATE(lat(ncell))
      ALLOCATE(bounds_lon(4,ncell))
      ALLOCATE(bounds_lat(4,ncell))
      ALLOCATE(mask(ncell))
      ncell=0
      data_n_index=0
      DO ind=1,ncell_glo
         IF (i_index_glo(ind)==mpi_rank) THEN
            ncell=ncell+1
            i_index(ncell)=ind-1
            lon(ncell)=lon_glo(ind)
            lat(ncell)=lat_glo(ind)
            bounds_lon(:,ncell)=bounds_lon_glo(:,ind)
            bounds_lat(:,ncell)=bounds_lat_glo(:,ind)
            field_A_srf(ncell,:)=i_index_glo(ind)
            IF (MOD(ind,8)>=0 .AND. MOD(ind,8)<2) THEN
               mask(ncell)=.TRUE.
               data_n_index=data_n_index+1
            ELSE
               mask(ncell)=.TRUE.
               data_n_index=data_n_index+1
            ENDIF
         ENDIF
      ENDDO

      ALLOCATE(data_i_index(data_n_index))
      data_n_index=0
      DO ind=1,ncell
         IF (mask(ind)) THEN
            data_n_index=data_n_index+1
            data_i_index(data_n_index)=ind-1
         ENDIF
      ENDDO

      ALLOCATE(return_lon(0:ncell-1))
      ALLOCATE(return_lat(0:ncell-1))
      ALLOCATE(return_mask(0:ncell-1))
      ALLOCATE(return_index(0:data_n_index-1))
      return_lon(0:ncell-1)=lon(1:ncell)    
      return_lat(0:ncell-1)=lat(1:ncell)
      return_index(0:data_n_index-1)= data_i_index(1:data_n_index) 
      CALL set_domain_mask(params, lon, lat, return_mask)

      return_ni=ncell
      return_nj=1


      IF (xios_is_valid_domain(TRIM(domain_id))) THEN
         CALL xios_set_domain_attr(TRIM(domain_id), TYPE="unstructured", ni_glo=ncell_glo, ni=ncell, ibegin=0, i_index=i_index)
         CALL xios_set_domain_attr(TRIM(domain_id), data_dim=1, data_ni=data_n_index, data_i_index=data_i_index, mask_1d=return_mask)
         CALL xios_set_domain_attr(TRIM(domain_id), lonvalue_1D=lon, latvalue_1D=lat, nvertex=4, bounds_lon_1D=bounds_lon, &
            bounds_lat_1D=bounds_lat)
         CALL xios_set_domain_attr(TRIM(domain_id), radius=1.0_8)
      ENDIF

   END SUBROUTINE init_domain_gaussian

   SUBROUTINE init_domain_ssea(domain_id, comm, params, return_ni, return_nj,               &
      return_lon,return_lat,return_mask, return_index)
      IMPLICIT NONE 
      CHARACTER(LEN=*) :: domain_id
      TYPE(tmodel_params) :: params

      INTEGER :: comm
      INTEGER :: return_ni
      INTEGER :: return_nj
      DOUBLE PRECISION, POINTER :: return_lon(:)
      DOUBLE PRECISION, POINTER :: return_lat(:)
      LOGICAL, POINTER :: return_mask(:)
      INTEGER, POINTER :: return_index(:)
      INTEGER :: mpi_rank, mpi_size
      INTEGER ::  ierr

      DOUBLE PRECISION, POINTER :: lon_glo2d(:,:), lat_glo2d(:,:)
      DOUBLE PRECISION, POINTER :: clo_glo2d(:,:,:), cla_glo2d(:,:,:)
      INTEGER, POINTER :: msk_glo2d(:,:)
      DOUBLE PRECISION, POINTER :: srf_glo2d(:,:)

      INTEGER :: ni_glo,nj_glo, ncrn, nbp

      INTEGER :: i, j, ipx, ic, nlat, npx, npy, ib, ie
      INTEGER, ALLOCATABLE :: glo_rank(:)
      INTEGER, ALLOCATABLE :: ila_pcx(:)
      DOUBLE PRECISION :: last_lat, curr_lon
      INTEGER, ALLOCATABLE :: i_index(:)
      DOUBLE PRECISION, ALLOCATABLE :: srf_loc2d(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: bounds_lon(:,:), bounds_lat(:,:)

      CALL MPI_COMM_RANK(comm,mpi_rank,ierr)
      CALL MPI_COMM_SIZE(comm,mpi_size,ierr)

      CALL read_oasis_grid(params, ni_glo, nj_glo, ncrn,&
         & lon_glo2d, lat_glo2d, clo_glo2d, cla_glo2d, msk_glo2d, srf_glo2d)

      ! Count the latitudes
      nlat = 1
      last_lat = lat_glo2d(0,0)
      DO i = 1, ni_glo-1
         IF (ABS(lat_glo2d(i,0) - last_lat) > 2.*EPSILON(1.0)) THEN
            nlat = nlat + 1
            last_lat = lat_glo2d(i,0)
         END IF
      END DO

      ! Choose the partition
      npy=INT(SQRT(mpi_size*1.))
      DO WHILE(MOD(mpi_size,npy) /= 0)
         npy = npy - 1
      END DO
      npx = mpi_size / npy

      ! Decomposition
      ALLOCATE(glo_rank(0:ni_glo-1))
      ALLOCATE(ila_pcx(0:npx-1))
      ib = 0
      DO i = 0, npy-1
         ! First step: decompose the domain in pseudo latitude bands
         ie = ib + ni_glo/npy
         IF (i < MOD(ni_glo,npy)) ie = ie + 1
         glo_rank(ib:ie-1) = i*npx
         ! Second step: decompose the pseudo latitude bands
         ila_pcx(:) = 0
         DO j = ib, ie-1
            curr_lon = lon_glo2d(j,0)
            IF (curr_lon > 360.0) curr_lon = curr_lon - 360.
            IF (curr_lon < 0.0) curr_lon = curr_lon + 360.
            ipx = MIN(FLOOR(npx*curr_lon/360.),npx-1)  
            glo_rank(j) = glo_rank(j) + ipx
            ila_pcx(ipx) = ila_pcx(ipx) + 1
         END DO
         ! Third step: balance them
         DO ipx = 0, npx - 1
            ila_pcx(ipx) = ila_pcx(ipx) - (ie-ib)/npx
            IF (ipx < MOD(ie-ib,npx)) ila_pcx(ipx) = ila_pcx(ipx) - 1
         END DO
         DO ipx = 0, npx - 2
            DO WHILE (ila_pcx(ipx) /=0)
               j = ib
               DO WHILE (j < ie-1)
                  IF (glo_rank(j) == i*npx + ipx .AND. &
                     & glo_rank(j) == glo_rank(j+1)-1) THEN
                     IF (ila_pcx(ipx) > 0) THEN
                        glo_rank(j) = glo_rank(j+1)
                        ila_pcx(ipx) = ila_pcx(ipx) - 1
                        ila_pcx(ipx+1) = ila_pcx(ipx+1) + 1
                     ELSE
                        glo_rank(j+1) = glo_rank(j)
                        ila_pcx(ipx) = ila_pcx(ipx) + 1
                        ila_pcx(ipx+1) = ila_pcx(ipx+1) - 1                      
                     END IF
                     j = j + 1
                  END IF
                  j = j + 1
                  IF (ila_pcx(ipx) == 0) EXIT
               END DO
            END DO
         END DO
         ! Move to next npy slice
         ib = ie
      END DO

      ! Count local elements and assign local values
      nbp = COUNT(glo_rank == mpi_rank)
      return_ni=nbp
      return_nj=1

      ALLOCATE(return_lon(0:nbp-1))
      ALLOCATE(return_lat(0:nbp-1))
      ALLOCATE(return_mask(0:nbp-1))
      ALLOCATE(return_index(0:nbp-1))
      ALLOCATE(i_index(0:nbp-1))
      ALLOCATE(bounds_lon(ncrn,0:nbp-1))
      ALLOCATE(bounds_lat(ncrn,0:nbp-1))
      ALLOCATE(srf_loc2d(0:0,0:nbp-1))

      j = 0
      DO i = 0, ni_glo-1
         IF (glo_rank(i) == mpi_rank) THEN
            return_lon(j) = lon_glo2D(i,0)
            return_lat(j) = lat_glo2D(i,0)
            return_mask(j) = msk_glo2D(i,0) == 0
            return_index(j) = j
            i_index(j) = i
            DO ic = 1, ncrn
               bounds_lon(ic,j) = clo_glo2d(i,0,ic) 
               bounds_lat(ic,j) = cla_glo2d(i,0,ic)
            END DO
!AP YANN Notice the inversion of indexes for 1d areas stored in 2d
            srf_loc2d(0,j) = srf_glo2d(i,0)
            j = j + 1 ! Next local cell
         END IF
      END DO

      IF ( .NOT. params%domain_mask) return_mask(:) = .TRUE.

      IF (xios_is_valid_domain(TRIM(domain_id))) THEN
         CALL xios_set_domain_attr(TRIM(domain_id), TYPE="unstructured", data_dim=1)
         CALL xios_set_domain_attr(TRIM(domain_id), ni_glo=ni_glo, ibegin=0, ni=nbp, i_index=i_index)
         CALL xios_set_domain_attr(TRIM(domain_id), lonvalue_1d=return_lon, latvalue_1d=return_lat, mask_1d=return_mask)
         CALL xios_set_domain_attr(TRIM(domain_id), bounds_lon_1d=bounds_lon, bounds_lat_1d=bounds_lat, nvertex=ncrn)
         CALL xios_set_domain_attr(TRIM(domain_id), area=srf_loc2d)
         CALL xios_set_domain_attr(TRIM(domain_id), radius=1.0_8)
      ENDIF

      DEALLOCATE(glo_rank, ila_pcx, i_index, srf_loc2d, bounds_lon, bounds_lat)

   END SUBROUTINE init_domain_ssea

   SUBROUTINE init_domain_lmdz(domain_id, comm, params, return_ni, return_nj,               &
      return_lon,return_lat,return_mask, return_index)
      IMPLICIT NONE 
      CHARACTER(LEN=*) :: domain_id
      TYPE(tmodel_params) :: params
      INTEGER :: comm
      INTEGER :: return_ni
      INTEGER :: return_nj
      DOUBLE PRECISION, POINTER :: return_lon(:)
      DOUBLE PRECISION, POINTER :: return_lat(:)
      LOGICAL, POINTER :: return_mask(:)
      INTEGER, POINTER :: return_index(:)
      INTEGER :: domain_proc_rank, domain_proc_size    
      INTEGER :: axis_proc_rank, axis_proc_size

      INTEGER :: mpi_rank, mpi_size
      INTEGER ::  ierr
      INTEGER :: ni,nj,ni_glo,nj_glo
      INTEGER :: ibegin,jbegin
      INTEGER :: nbp,nbp_glo, offset
      DOUBLE PRECISION, ALLOCATABLE :: lon_glo(:), lat_glo(:), lon(:), lat(:)
      LOGICAL,ALLOCATABLE :: mask(:)
      LOGICAL,ALLOCATABLE :: dom_mask(:)
      INTEGER :: i,j

      CALL MPI_COMM_RANK(comm,mpi_rank,ierr)
      CALL MPI_COMM_SIZE(comm,mpi_size,ierr)

      CALL get_decomposition(comm, params, domain_proc_size, domain_proc_rank, axis_proc_size, axis_proc_rank)

      ni_glo=params%ni
      nj_glo=params%nj
      nbp_glo=ni_glo*nj_glo
      nbp=nbp_glo/domain_proc_size
      IF (domain_proc_rank < MOD(nbp_glo,domain_proc_size) ) THEN
         nbp=nbp+1
         offset=nbp*domain_proc_rank
      ELSE
         offset=nbp*domain_proc_rank + MOD(nbp_glo, domain_proc_size)
      ENDIF


      ibegin=0 ; ni=ni_glo
      jbegin=offset / ni_glo

      nj = (offset+nbp-1) / ni_glo - jbegin + 1 

      offset=offset-jbegin*ni

      ALLOCATE(lon(0:ni-1), lat(0:nj-1), mask(0:ni*nj-1), dom_mask(0:ni*nj-1))
      mask(:)=.FALSE.
      mask(offset:offset+nbp-1)=.TRUE.

      ALLOCATE(lon_glo(0:ni_glo-1), lat_glo(0:nj_glo-1))

      DO i=0,ni_glo-1
         lon_glo(i)=-180+(i+0.5)*(360./ni_glo)
      ENDDO

      DO j=0,nj_glo-1
         lat_glo(j)=-90+(j+0.5)*(180./nj_glo)
      ENDDO

      lon(:)=lon_glo(:)
      lat(:)=lat_glo(jbegin:jbegin+nj-1)

      ALLOCATE(return_lon(0:ni*nj-1))
      ALLOCATE(return_lat(0:ni*nj-1))
      ALLOCATE(return_mask(0:ni*nj-1))
      ALLOCATE(return_index(0:ni*nj-1))

      DO j=0,nj-1
         DO i=0,ni-1
            return_lon(i+j*ni)=lon(i)
            return_lat(i+j*ni)=lat(j)
            return_index(i+j*ni)=i+j*ni
         ENDDO
      ENDDO

      CALL set_domain_mask(params, return_lon,return_lat, dom_mask)

      return_mask = mask .AND. dom_mask

      return_ni=ni
      return_nj=nj

      IF (xios_is_valid_domain(TRIM(domain_id))) THEN
         CALL xios_set_domain_attr(TRIM(domain_id), TYPE="rectilinear", ni_glo=ni_glo, ibegin=ibegin, ni=ni, nj_glo=nj_glo, &
            jbegin=jbegin, nj=nj)
         CALL xios_set_domain_attr(TRIM(domain_id), data_dim=2, lonvalue_1d=lon, latvalue_1d=lat, mask_1d=return_mask)
         CALL xios_set_domain_attr(TRIM(domain_id), radius=1.0_8)
      ENDIF

   END SUBROUTINE init_domain_lmdz

   SUBROUTINE init_domain_bggd(domain_id, comm, params, return_ni, return_nj,               &
      return_lon,return_lat,return_mask, return_index)
      IMPLICIT NONE 
      CHARACTER(LEN=*) :: domain_id
      TYPE(tmodel_params) :: params
      INTEGER :: comm
      INTEGER :: return_ni
      INTEGER :: return_nj
      DOUBLE PRECISION, POINTER :: return_lon(:)
      DOUBLE PRECISION, POINTER :: return_lat(:)
      LOGICAL, POINTER :: return_mask(:)
      INTEGER, POINTER :: return_index(:)

      INTEGER :: mpi_rank, mpi_size
      INTEGER ::  ierr

      DOUBLE PRECISION, POINTER :: lon_glo2d(:,:), lat_glo2d(:,:)
      DOUBLE PRECISION, POINTER :: clo_glo2d(:,:,:), cla_glo2d(:,:,:)
      INTEGER, POINTER :: msk_glo2d(:,:)
      DOUBLE PRECISION, POINTER :: srf_glo2d(:,:)

      INTEGER :: ni,nj,ni_glo,nj_glo, ncrn
      INTEGER :: ibegin,jbegin
      INTEGER :: nbp,nbp_glo, offset
      DOUBLE PRECISION, ALLOCATABLE :: lon2d(:,:), lat2d(:,:), srf_loc2d(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: bounds_lon(:,:,:), bounds_lat(:,:,:)
      LOGICAL,ALLOCATABLE :: mask(:)
      LOGICAL,ALLOCATABLE :: dom_mask(:)
      INTEGER :: i,j,ij,ic

      CALL MPI_COMM_RANK(comm,mpi_rank,ierr)
      CALL MPI_COMM_SIZE(comm,mpi_size,ierr)

      CALL read_oasis_grid(params, ni_glo, nj_glo, ncrn,&
         & lon_glo2d, lat_glo2d, clo_glo2d, cla_glo2d, msk_glo2d, srf_glo2d)

      nbp_glo=ni_glo*nj_glo
      nbp=nbp_glo/mpi_size
      IF (mpi_rank < MOD(nbp_glo,mpi_size) ) THEN
         nbp=nbp+1
         offset=nbp*mpi_rank
      ELSE
         offset=nbp*mpi_rank + MOD(nbp_glo, mpi_size)
      ENDIF

      ibegin=0 ; ni=ni_glo
      jbegin=offset / ni_glo

      nj = (offset+nbp-1) / ni_glo - jbegin + 1 

      offset=offset-jbegin*ni

      ALLOCATE(mask(0:ni*nj-1), dom_mask(0:ni*nj-1))
      ALLOCATE(lon2d(0:ni-1,0:nj-1), lat2d(0:ni-1,0:nj-1))
      mask(:)=.FALSE.
      mask(offset:offset+nbp-1)=.TRUE.

      lon2d(:,:)=lon_glo2d(ibegin:ibegin+ni-1,jbegin:jbegin+nj-1)
      lat2d(:,:)=lat_glo2d(ibegin:ibegin+ni-1,jbegin:jbegin+nj-1)

      ALLOCATE(bounds_lon(ncrn,0:ni-1,0:nj-1))
      ALLOCATE(bounds_lat(ncrn,0:ni-1,0:nj-1))
      ALLOCATE(srf_loc2D(0:ni-1,0:nj-1))

      srf_loc2D(:,:)=srf_glo2d(ibegin:ibegin+ni-1,jbegin:jbegin+nj-1)

      ALLOCATE(return_lon(0:ni*nj-1))
      ALLOCATE(return_lat(0:ni*nj-1))
      ALLOCATE(return_mask(0:ni*nj-1))
      ALLOCATE(return_index(0:ni*nj-1))

      DO j=0,nj-1
         DO i=0,ni-1
            ij = i+j*ni
            return_lon(ij)=lon_glo2d(ibegin+i,jbegin+j)
            return_lat(ij)=lat_glo2d(ibegin+i,jbegin+j)
            dom_mask(ij) = msk_glo2d(ibegin+i,jbegin+j) == 0
            return_index(ij)=ij
            DO ic = 1, ncrn
               bounds_lon(ic,i,j) = clo_glo2d(ibegin+i,jbegin+j,ic)
               bounds_lat(ic,i,j) = cla_glo2d(ibegin+i,jbegin+j,ic)
            END DO
         ENDDO
      ENDDO

      return_mask = mask .AND. dom_mask
      IF ( .NOT. params%domain_mask ) return_mask = mask

      return_ni=ni
      return_nj=nj

      IF (xios_is_valid_domain(TRIM(domain_id))) THEN
         CALL xios_set_domain_attr(TRIM(domain_id), TYPE="rectilinear", data_dim=2)
         CALL xios_set_domain_attr(TRIM(domain_id), ni_glo=ni_glo, ibegin=ibegin, ni=ni)
         CALL xios_set_domain_attr(TRIM(domain_id), nj_glo=nj_glo, jbegin=jbegin, nj=nj)
         CALL xios_set_domain_attr(TRIM(domain_id), lonvalue_2d=lon2d, latvalue_2d=lat2d, mask_1d=return_mask)
         CALL xios_set_domain_attr(TRIM(domain_id), bounds_lon_2d=bounds_lon, bounds_lat_2d=bounds_lat, nvertex=ncrn)
         CALL xios_set_domain_attr(TRIM(domain_id), area=srf_loc2d)
         CALL xios_set_domain_attr(TRIM(domain_id), radius=1.0_8)
      ENDIF

      DEALLOCATE(lon2d, lat2d, srf_loc2d, bounds_lon, bounds_lat, mask, dom_mask)
      
   END SUBROUTINE init_domain_bggd


   SUBROUTINE init_domain_nemo(domain_id, comm, params, return_ni, return_nj,               &
      return_lon,return_lat,return_mask, return_index)
      IMPLICIT NONE 
      CHARACTER(LEN=*) :: domain_id
      TYPE(tmodel_params) :: params
      INTEGER :: comm
      INTEGER :: return_ni
      INTEGER :: return_nj
      DOUBLE PRECISION, POINTER :: return_lon(:)
      DOUBLE PRECISION, POINTER :: return_lat(:)
      LOGICAL, POINTER :: return_mask(:)
      INTEGER, POINTER :: return_index(:)
      INTEGER :: domain_proc_rank, domain_proc_size    
      INTEGER :: axis_proc_rank, axis_proc_size

      INTEGER :: mpi_rank, mpi_size
      INTEGER ::  ierr
      INTEGER :: ni,nj,ni_glo,nj_glo
      INTEGER :: ibegin,jbegin
      INTEGER :: offset_i, offset_j
      DOUBLE PRECISION, ALLOCATABLE :: lon_glo(:), lat_glo(:), bounds_lon_glo(:,:), bounds_lat_glo(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: lon(:,:), lat(:,:), bounds_lon(:,:,:), bounds_lat(:,:,:) 
      INTEGER :: i,j, ij, n, rank
      INTEGER :: nproc_i, nproc_j, nholes, pos_hole
      INTEGER,ALLOCATABLE :: size_i(:), begin_i(:), size_j(:), begin_j(:)

      CALL MPI_COMM_RANK(comm,mpi_rank,ierr)
      CALL MPI_COMM_SIZE(comm,mpi_size,ierr)

      CALL get_decomposition(comm, params, domain_proc_size, domain_proc_rank, axis_proc_size, axis_proc_rank)
      ni_glo=params%ni
      nj_glo=params%nj

      n=INT(SQRT(mpi_size*1.))
      nproc_i=n
      nproc_j=n
      IF ( n*n == mpi_size) THEN
         ! do nothing
      ELSE IF ( (n+1)*n < mpi_size) THEN
         nproc_i=nproc_i+1
         nproc_j=nproc_j+1
      ELSE 
         nproc_i=nproc_i+1
      ENDIF

      nholes=nproc_i*nproc_j-mpi_size

      ALLOCATE(size_i(0:nproc_i-1))
      ALLOCATE(begin_i(0:nproc_i-1))
      DO i=0,nproc_i-1
         size_i(i)=ni_glo/nproc_i
         IF (i<MOD(ni_glo,nproc_i)) size_i(i)=size_i(i)+1
         IF (i==0) THEN
            begin_i(i)=0
         ELSE
            begin_i(i)=begin_i(i-1)+size_i(i-1)
         ENDIF
      ENDDO

      ALLOCATE(size_j(0:nproc_j-1))
      ALLOCATE(begin_j(0:nproc_j-1))
      DO j=0,nproc_j-1
         size_j(j)=nj_glo/nproc_j
         IF (j<MOD(nj_glo,nproc_j)) size_j(j)=size_j(j)+1
         IF (j==0) THEN
            begin_j(j)=0
         ELSE
            begin_j(j)=begin_j(j-1)+size_j(j-1)
         ENDIF
      ENDDO


      pos_hole=0
      rank=0
      DO j=0,nproc_j-1
         DO i=0,nproc_i-1

            ij = j*nproc_i + i
            IF (pos_hole<nholes) THEN
               IF ( MOD(ij,(nproc_i*nproc_j/nholes)) == 0) THEN
                  pos_hole=pos_hole+1
                  CYCLE
               ENDIF
            ENDIF

            IF (mpi_rank==rank) THEN
               ibegin = begin_i(i)
               ni = size_i(i)
               jbegin = begin_j(j)
               nj = size_j(j)
            ENDIF
            rank=rank+1
         ENDDO
      ENDDO

      ALLOCATE(lon_glo(0:ni_glo-1), lat_glo(0:nj_glo-1))
      ALLOCATE(bounds_lon_glo(4,0:ni_glo-1), bounds_lat_glo(4,0:nj_glo-1))

      DO i=0,ni_glo-1
         lon_glo(i)=-180+(i+0.5)*(360./ni_glo)
         bounds_lon_glo(1,i)= -180+(i)*(360./ni_glo)
         bounds_lon_glo(2,i)= -180+(i+1)*(360./ni_glo)
      ENDDO

      DO j=0,nj_glo-1
         lat_glo(j)=-90+(j+0.5)*(180./nj_glo)
         bounds_lat_glo(1,j)= -90+(j)*(180./nj_glo)
         bounds_lat_glo(2,j)= -90+(j+1)*(180./nj_glo)
      ENDDO

      offset_i=2    ! halo of 2 on i
      offset_j=1    ! halo of 1 on j

      ALLOCATE(lon(0:ni-1,0:nj-1))
      ALLOCATE(lat(0:ni-1,0:nj-1))
      ALLOCATE(bounds_lon(4,0:ni-1,0:nj-1))
      ALLOCATE(bounds_lat(4,0:ni-1,0:nj-1))

      ALLOCATE(return_lon(0:ni*nj-1))
      ALLOCATE(return_lat(0:ni*nj-1))
      ALLOCATE(return_mask(0:ni*nj-1))
      ALLOCATE(return_index(0:(ni+2*offset_i)*(nj+2*offset_j)-1))

      return_index=-1 
      DO j=0,nj-1
         DO i=0,ni-1
            ij=j*ni+i
            return_lon(ij)=lon_glo(ibegin+i)
            return_lat(ij)=lat_glo(jbegin+j)
            lon(i,j)=return_lon(ij)
            lat(i,j)=return_lat(ij)
            bounds_lon(1,i,j)=bounds_lon_glo(2,ibegin+i)
            bounds_lon(2,i,j)=bounds_lon_glo(1,ibegin+i)
            bounds_lon(3,i,j)=bounds_lon_glo(1,ibegin+i)
            bounds_lon(4,i,j)=bounds_lon_glo(2,ibegin+i)
            bounds_lat(1,i,j)=bounds_lat_glo(1,jbegin+j)
            bounds_lat(2,i,j)=bounds_lat_glo(1,jbegin+j)
            bounds_lat(3,i,j)=bounds_lat_glo(2,jbegin+j)
            bounds_lat(4,i,j)=bounds_lat_glo(2,jbegin+j)

            ij=(j+offset_j)*(ni+2*offset_i)+i+offset_i
            return_index(ij)=i+j*ni
         ENDDO
      ENDDO

      CALL set_domain_mask(params, return_lon,return_lat, return_mask)

      return_ni=ni
      return_nj=nj

      IF (xios_is_valid_domain(TRIM(domain_id))) THEN
         CALL xios_set_domain_attr(TRIM(domain_id), TYPE="curvilinear", data_dim=2)
         CALL xios_set_domain_attr(TRIM(domain_id), ni_glo=ni_glo, ibegin=ibegin, ni=ni, data_ibegin=-offset_i, data_ni=ni+2*offset_i)
         CALL xios_set_domain_attr(TRIM(domain_id), nj_glo=nj_glo, jbegin=jbegin, nj=nj, data_jbegin=-offset_j, data_nj=nj+2*offset_j)
         CALL xios_set_domain_attr(TRIM(domain_id), data_dim=2, lonvalue_2d=lon, latvalue_2d=lat, mask_1d=return_mask)
         CALL xios_set_domain_attr(TRIM(domain_id), bounds_lon_2d=bounds_lon, bounds_lat_2d=bounds_lat, nvertex=4)
         CALL xios_set_domain_attr(TRIM(domain_id), radius=1.0_8)
      ENDIF

   END SUBROUTINE init_domain_nemo


   SUBROUTINE init_domain_orca(domain_id, comm, params, return_ni, return_nj,               &
      return_lon,return_lat,return_mask, return_index)
      IMPLICIT NONE 
      CHARACTER(LEN=*) :: domain_id
      TYPE(tmodel_params) :: params
      INTEGER :: comm
      INTEGER :: return_ni
      INTEGER :: return_nj
      DOUBLE PRECISION, POINTER :: return_lon(:)
      DOUBLE PRECISION, POINTER :: return_lat(:)
      LOGICAL, POINTER :: return_mask(:)
      INTEGER, POINTER :: return_index(:)
      INTEGER :: mpi_rank, mpi_size
      INTEGER ::  ierr

      DOUBLE PRECISION, POINTER :: lon_glo2d(:,:), lat_glo2d(:,:)
      DOUBLE PRECISION, POINTER :: clo_glo2d(:,:,:), cla_glo2d(:,:,:)
      INTEGER, POINTER :: msk_glo2d(:,:)
      DOUBLE PRECISION, POINTER :: srf_glo2d(:,:)

      INTEGER :: ni,nj,ni_glo,nj_glo, ncrn
      INTEGER :: ibegin,jbegin
      INTEGER :: offset_i, offset_j
      DOUBLE PRECISION, ALLOCATABLE :: lon(:,:), lat(:,:), bounds_lon(:,:,:), bounds_lat(:,:,:),  srf_loc2d(:,:)
      INTEGER :: i, j, ij, rank
      INTEGER :: nproc_i, nproc_j
      INTEGER,ALLOCATABLE :: size_i(:), begin_i(:), size_j(:), begin_j(:)

      CALL MPI_COMM_RANK(comm,mpi_rank,ierr)
      CALL MPI_COMM_SIZE(comm,mpi_size,ierr)

      CALL read_oasis_grid(params, ni_glo, nj_glo, ncrn,&
         & lon_glo2d, lat_glo2d, clo_glo2d, cla_glo2d, msk_glo2d, srf_glo2d)

      nproc_j=INT(SQRT(mpi_size*1.))
      DO WHILE(MOD(mpi_size,nproc_j) /= 0)
         nproc_j = nproc_j - 1
      END DO
      nproc_i = mpi_size / nproc_j

      ALLOCATE(size_i(0:nproc_i-1))
      ALLOCATE(begin_i(0:nproc_i-1))
      DO i=0,nproc_i-1
         size_i(i)=ni_glo/nproc_i
         IF (i<MOD(ni_glo,nproc_i)) size_i(i)=size_i(i)+1
         IF (i==0) THEN
            begin_i(i)=0
         ELSE
            begin_i(i)=begin_i(i-1)+size_i(i-1)
         ENDIF
      ENDDO

      ALLOCATE(size_j(0:nproc_j-1))
      ALLOCATE(begin_j(0:nproc_j-1))
      DO j=0,nproc_j-1
         size_j(j)=nj_glo/nproc_j
         IF (j<MOD(nj_glo,nproc_j)) size_j(j)=size_j(j)+1
         IF (j==0) THEN
            begin_j(j)=0
         ELSE
            begin_j(j)=begin_j(j-1)+size_j(j-1)
         ENDIF
      ENDDO

      rank=0
      DO j=0,nproc_j-1
         DO i=0,nproc_i-1
            IF (mpi_rank==rank) THEN
               ibegin = begin_i(i)
               ni = size_i(i)
               jbegin = begin_j(j)
               nj = size_j(j)
            ENDIF
            rank=rank+1
         ENDDO
      ENDDO

      offset_i=2    ! halo of 2 on i
      offset_j=1    ! halo of 1 on j

      ALLOCATE(lon(0:ni-1,0:nj-1))
      ALLOCATE(lat(0:ni-1,0:nj-1))
      ALLOCATE(bounds_lon(ncrn,0:ni-1,0:nj-1))
      ALLOCATE(bounds_lat(ncrn,0:ni-1,0:nj-1))
      ALLOCATE(srf_loc2D(0:ni-1,0:nj-1))

      ALLOCATE(return_lon(0:ni*nj-1))
      ALLOCATE(return_lat(0:ni*nj-1))
      ALLOCATE(return_mask(0:ni*nj-1))
      ALLOCATE(return_index(0:(ni+2*offset_i)*(nj+2*offset_j)-1))


      return_index=-1 
      DO j=0,nj-1
         DO i=0,ni-1
            ij=j*ni+i
            return_lon(ij)=lon_glo2d(ibegin+i,jbegin+j)
            return_lat(ij)=lat_glo2d(ibegin+i,jbegin+j)
            return_mask(ij) = msk_glo2d(ibegin+i,jbegin+j) == 0
            srf_loc2d(i,j) = srf_glo2d(ibegin+i,jbegin+j)
            lon(i,j)=return_lon(ij)
            lat(i,j)=return_lat(ij)
            DO ij = 1, ncrn
               bounds_lon(ij,i,j) = clo_glo2d(ibegin+i,jbegin+j,ij)
               bounds_lat(ij,i,j) = cla_glo2d(ibegin+i,jbegin+j,ij)
            END DO

            ij=(j+offset_j)*(ni+2*offset_i)+i+offset_i
            return_index(ij)=i+j*ni
         ENDDO
      ENDDO

      return_ni=ni
      return_nj=nj

      IF (xios_is_valid_domain(TRIM(domain_id))) THEN
         CALL xios_set_domain_attr(TRIM(domain_id), TYPE="curvilinear", data_dim=2)
         CALL xios_set_domain_attr(TRIM(domain_id), ni_glo=ni_glo, ibegin=ibegin, ni=ni, data_ibegin=-offset_i, data_ni=ni+2*offset_i)
         CALL xios_set_domain_attr(TRIM(domain_id), nj_glo=nj_glo, jbegin=jbegin, nj=nj, data_jbegin=-offset_j, data_nj=nj+2*offset_j)
         CALL xios_set_domain_attr(TRIM(domain_id), data_dim=2, lonvalue_2d=lon, latvalue_2d=lat, mask_1d=return_mask)
         CALL xios_set_domain_attr(TRIM(domain_id), bounds_lon_2d=bounds_lon, bounds_lat_2d=bounds_lat, nvertex=ncrn)
         CALL xios_set_domain_attr(TRIM(domain_id), area=srf_loc2d)
         CALL xios_set_domain_attr(TRIM(domain_id), radius=1.0_8)
      ENDIF

      DEALLOCATE(lon, lat, bounds_lon, bounds_lat,  srf_loc2d, size_i, begin_i, size_j, begin_j)

   END SUBROUTINE init_domain_orca

   SUBROUTINE init_domain_icos(domain_id, comm, params, return_ni, return_nj,               &
      return_lon,return_lat,return_mask, return_index)
      IMPLICIT NONE 
      CHARACTER(LEN=*) :: domain_id
      TYPE(tmodel_params) :: params
      INTEGER :: comm
      INTEGER :: return_ni
      INTEGER :: return_nj
      DOUBLE PRECISION, POINTER :: return_lon(:)
      DOUBLE PRECISION, POINTER :: return_lat(:)
      LOGICAL, POINTER :: return_mask(:)
      INTEGER, POINTER :: return_index(:)
      INTEGER :: mpi_rank, mpi_size
      INTEGER ::  ierr

      DOUBLE PRECISION, POINTER :: lon_glo2d(:,:), lat_glo2d(:,:)
      DOUBLE PRECISION, POINTER :: clo_glo2d(:,:,:), cla_glo2d(:,:,:)
      INTEGER, POINTER :: msk_glo2d(:,:)
      DOUBLE PRECISION, POINTER :: srf_glo2d(:,:)

      INTEGER :: ni_glo,nj_glo, ncrn
      INTEGER :: nbp,nbp_glo, offset

      DOUBLE PRECISION, ALLOCATABLE :: lon(:), lat(:), srf_loc2d(:,:)
      DOUBLE PRECISION, ALLOCATABLE :: bounds_lon(:,:), bounds_lat(:,:)

      INTEGER :: i,ic

      CALL MPI_COMM_RANK(comm,mpi_rank,ierr)
      CALL MPI_COMM_SIZE(comm,mpi_size,ierr)

      CALL read_oasis_grid(params, ni_glo, nj_glo, ncrn,&
         & lon_glo2d, lat_glo2d, clo_glo2d, cla_glo2d, msk_glo2d, srf_glo2d)


      nbp_glo=ni_glo
      nbp=nbp_glo/mpi_size
      IF (mpi_rank < MOD(nbp_glo,mpi_size) ) THEN
         nbp=nbp+1
         offset=nbp*mpi_rank
      ELSE
         offset=nbp*mpi_rank + MOD(nbp_glo, mpi_size)
      ENDIF

      ALLOCATE(lat(0:nbp-1))
      ALLOCATE(lon(0:nbp-1))
      ALLOCATE(bounds_lon(ncrn,0:nbp-1))
      ALLOCATE(bounds_lat(ncrn,0:nbp-1))
      ALLOCATE(return_lon(0:nbp-1))
      ALLOCATE(return_lat(0:nbp-1))
      ALLOCATE(return_index(0:nbp-1))
      ALLOCATE(return_mask(0:nbp-1))
      ALLOCATE(srf_loc2d(0:0,0:nbp-1))

      DO i=0,nbp-1
         lat(i)=lat_glo2d(i+offset,0)
         lon(i)=lon_glo2d(i+offset,0)
         DO ic = 1, ncrn
            bounds_lon(ic,i) = clo_glo2d(i+offset,0,ic) 
            bounds_lat(ic,i) = cla_glo2d(i+offset,0,ic)
         END DO
         return_mask(i) = msk_glo2d(i+offset,0) == 0
!AP YANN Notice the inversion of indexes for 1d areas stored in 2d
         srf_loc2d(0,i) = srf_glo2d(i+offset,0)
         return_index(i)=i 
      ENDDO
      
      IF ( .NOT. params%domain_mask ) return_mask(:) = .TRUE.
      
      return_lon=lon
      return_lat=lat

      return_ni=nbp
      return_nj=1

      IF (xios_is_valid_domain(TRIM(domain_id))) THEN
         CALL xios_set_domain_attr(TRIM(domain_id), TYPE="unstructured", data_dim=1)
         CALL xios_set_domain_attr(TRIM(domain_id), ni_glo=ni_glo, ibegin=offset, ni=nbp)
         CALL xios_set_domain_attr(TRIM(domain_id), lonvalue_1d=lon, latvalue_1d=lat, mask_1d=return_mask)
         CALL xios_set_domain_attr(TRIM(domain_id), bounds_lon_1d=bounds_lon, bounds_lat_1d=bounds_lat, nvertex=ncrn)
         CALL xios_set_domain_attr(TRIM(domain_id), area=srf_loc2d)
         CALL xios_set_domain_attr(TRIM(domain_id), radius=1.0_8)
      ENDIF

      DEALLOCATE(lon, lat, srf_loc2d, bounds_lon, bounds_lat)

   END SUBROUTINE init_domain_icos


   SUBROUTINE set_domain_mask(params, lon,lat, mask)
      IMPLICIT NONE 
      TYPE(tmodel_params) :: params
      DOUBLE PRECISION    :: lon(:)
      DOUBLE PRECISION    :: lat(:)
      LOGICAL             :: mask(:)

      mask(:)=.TRUE.
      IF (params%domain_mask) THEN
         WHERE (lon(:)-2*lat(:)>-10 .AND. lon(:)-2*lat(:) <10) mask(:)=.FALSE.
         WHERE (2*lat(:)+lon(:)>-10 .AND. 2*lat(:)+lon(:)<10) mask(:)=.FALSE.
      ENDIF

   END SUBROUTINE set_domain_mask


   SUBROUTINE init_field2D_vortex(params, lon, lat, mask, return_field)
      IMPLICIT NONE
      TYPE(tmodel_params) :: params
      DOUBLE PRECISION, POINTER :: lon(:)
      DOUBLE PRECISION, POINTER :: lat(:)
      LOGICAL, POINTER :: mask(:)
      DOUBLE PRECISION, POINTER :: return_field(:)

      DOUBLE PRECISION, PARAMETER :: dp_pi=3.14159265359
      DOUBLE PRECISION, PARAMETER :: dLon0 = 5.5
      DOUBLE PRECISION, PARAMETER :: dLat0 = 0.2
      DOUBLE PRECISION, PARAMETER :: dR0   = 3.0
      DOUBLE PRECISION, PARAMETER :: dD    = 5.0
      DOUBLE PRECISION, PARAMETER :: dT    = 6.0
      DOUBLE PRECISION :: dp_length, dp_conv
      INTEGER :: i,xy

      DOUBLE PRECISION :: dSinC, dCosC, dCosT, dSinT
      DOUBLE PRECISION :: dTrm, dX, dY, dZ
      DOUBLE PRECISION :: dlon, dlat
      DOUBLE PRECISION :: dRho, dVt, dOmega
      
      xy=SIZE(mask)

      ALLOCATE(return_field(0:xy-1))

      dp_conv = dp_pi/180.
      dSinC = SIN( dLat0 )
      dCosC = COS( dLat0 )

      DO i=0,xy-1
         IF (mask(i)) THEN
      
            ! Find the rotated longitude and latitude of a point on a sphere
            !		with pole at (dLon0, dLat0).
            dCosT = COS( lat(i)*dp_conv )
            dSinT = SIN( lat(i)*dp_conv )

            dTrm = dCosT * COS( lon(i)*dp_conv - dLon0 )
            dX   = dSinC * dTrm - dCosC * dSinT
            dY   = dCosT * SIN( lon(i)*dp_conv - dLon0 )
            dZ   = dSinC * dSinT + dCosC * dTrm

            dlon = ATAN2( dY, dX )
            IF( dlon < 0.0 ) dlon = dlon + 2.0 * dp_pi
            dlat = ASIN( dZ )
            
            dRho = dR0 * COS(dlat)
            dVt = 3.0 * SQRT(3.0)/2.0/COSH(dRho)/COSH(dRho)*TANH(dRHo)
            IF (dRho == 0.0) THEN
               dOmega = 0.0
            ELSE
               dOmega = dVt / dRho
            END IF

            RETURN_FIELD(i) = 2.0 * ( 1.0 + TANH( dRho / dD * SIN( dLon - dOmega * dT ) ) )

         END IF
      END DO
      
   END SUBROUTINE init_field2D_vortex

   SUBROUTINE init_field2D_academic(params, lon, lat, mask, return_field)
      IMPLICIT NONE
      TYPE(tmodel_params) :: params
      DOUBLE PRECISION, POINTER :: lon(:)
      DOUBLE PRECISION, POINTER :: lat(:)
      LOGICAL, POINTER :: mask(:)
      DOUBLE PRECISION, POINTER :: return_field(:)

      DOUBLE PRECISION, PARAMETER :: coef=2., dp_pi=3.14159265359
      DOUBLE PRECISION :: dp_length, dp_conv
      INTEGER :: i,xy

      ! Analytical Gulf Stream
      DOUBLE PRECISION :: gf_coef, gf_ori_lon, gf_ori_lat, &
         & gf_end_lon, gf_end_lat, gf_dmp_lon, gf_dmp_lat
      DOUBLE PRECISION :: gf_per_lon
      DOUBLE PRECISION :: dx, dy, dr, dth, dc, dr0, dr1

      ! Parameters for analytical function
      dp_length= 1.2*dp_pi
      dp_conv=dp_pi/180.
      gf_coef = params%gf_coef ! Coefficient for Gulf Stream term (0.0 = no Gulf Stream)
      gf_ori_lon = -80.0 ! Origin of the Gulf Stream (longitude in deg)
      gf_ori_lat =  25.0 ! Origin of the Gulf Stream (latitude in deg) 
      gf_end_lon =  -1.8 ! End point of the Gulf Stream (longitude in deg)
      gf_end_lat =  50.0 ! End point of the Gulf Stream (latitude in deg) 
      gf_dmp_lon = -25.5 ! Point of the Gulf Stream decrease (longitude in deg)
      gf_dmp_lat =  55.5 ! Point of the Gulf Stream decrease (latitude in deg) 

      xy=SIZE(mask)

      ALLOCATE(return_field(0:xy-1))

      dr0 = SQRT(((gf_end_lon - gf_ori_lon)*dp_conv)**2 + &
         & ((gf_end_lat - gf_ori_lat)*dp_conv)**2)
      dr1 = SQRT(((gf_dmp_lon - gf_ori_lon)*dp_conv)**2 + &
         & ((gf_dmp_lat - gf_ori_lat)*dp_conv)**2)

      DO i=0,xy-1
         IF (mask(i)) THEN
            return_field(i)=(coef-COS(dp_pi*(ACOS(COS(lat(i)*dp_conv)*&
               COS(lon(i)*dp_conv))/dp_length)))
            gf_per_lon = lon(i)
            IF (gf_per_lon > 180.0) gf_per_lon = gf_per_lon - 360.0
            IF (gf_per_lon < -180.0) gf_per_lon = gf_per_lon + 360.0
            dx = (gf_per_lon - gf_ori_lon)*dp_conv
            dy = (lat(i) - gf_ori_lat)*dp_conv
            dr = SQRT(dx*dx + dy*dy)
            dth = ATAN2(dy, dx)
            dc = 1.3 * gf_coef
            IF (dr > dr0) dc = 0.0
            IF (dr > dr1) dc = dc * COS(dp_pi*0.5*(dr-dr1)/(dr0-dr1))
            return_field(i) = return_field(i) + &
               & (MAX(1000.0*SIN(0.4*(0.5*dr+dth) + &
               &  0.007*COS(50.0*dth) + 0.37*dp_pi),999.0) - 999.0) * &
               & dc
         ENDIF
      ENDDO

   END SUBROUTINE init_field2D_academic

   SUBROUTINE init_field2D_one(mask, return_field)

      IMPLICIT NONE
      LOGICAL, POINTER :: mask(:)
      DOUBLE PRECISION, POINTER :: return_field(:)

      INTEGER :: xy

      xy=SIZE(mask)

      ALLOCATE(return_field(0:xy-1))
      return_field(:)=1.0

   END SUBROUTINE init_field2D_one

   SUBROUTINE init_field2D_rank(comm, mask, return_field)

      IMPLICIT NONE
      INTEGER :: comm
      LOGICAL, POINTER :: mask(:)
      DOUBLE PRECISION, POINTER :: return_field(:)

      INTEGER ::  rank,ierr
      INTEGER :: xy

      CALL MPI_COMM_RANK(comm,rank,ierr)

      xy=SIZE(mask)

      ALLOCATE(return_field(0:xy-1))
      return_field(:)=rank

   END SUBROUTINE init_field2D_rank

   SUBROUTINE init_field2D_mask(comm, mask, return_field)

      IMPLICIT NONE
      INTEGER :: comm
      LOGICAL, POINTER :: mask(:)
      DOUBLE PRECISION, POINTER :: return_field(:)

      INTEGER ::  rank,ierr
      INTEGER :: xy

      CALL MPI_COMM_RANK(comm,rank,ierr)

      xy=SIZE(mask)

      ALLOCATE(return_field(0:xy-1))
      WHERE (mask)
         return_field(:) = 1.0
      ELSEWHERE
         return_field(:) = 0.0
      END WHERE

   END SUBROUTINE init_field2D_mask

   SUBROUTINE read_oasis_grid(params, ni_glo, nj_glo, ncrn,&
      & lon_glo2d, lat_glo2d, clo_glo2d, cla_glo2d, msk_glo2d, srf_glo2d)
      IMPLICIT NONE 
      TYPE(tmodel_params), INTENT(IN) :: params
      INTEGER, INTENT(OUT) :: ni_glo, nj_glo, ncrn
      DOUBLE PRECISION, POINTER :: lon_glo2d(:,:), lat_glo2d(:,:)
      DOUBLE PRECISION, POINTER :: clo_glo2d(:,:,:), cla_glo2d(:,:,:)
      INTEGER, POINTER :: msk_glo2d(:,:)
      DOUBLE PRECISION, POINTER :: srf_glo2d(:,:) 
      ! Local variables
      INTEGER ::  ierr
      CHARACTER(len=256) :: grid_filename
      CHARACTER(len=256) :: mask_filename
      CHARACTER(len=256) :: surf_filename
      CHARACTER(len=8)           :: cl_nam ! cl_grd+.lon,+.lat ...
      INTEGER :: il_file_id, il_lon_id, il_lat_id, il_clo_id, il_cla_id
      INTEGER :: il_msk_id, il_srf_id
      INTEGER :: lon_dims, lat_dims
      INTEGER, DIMENSION(NF90_MAX_VAR_DIMS) :: lon_dims_ids,lat_dims_ids
      INTEGER, DIMENSION(NF90_MAX_VAR_DIMS) :: lon_dims_len,lat_dims_len
      INTEGER :: i
      INTEGER,  DIMENSION(:), ALLOCATABLE   :: ila_dim, ila_what

      grid_filename = TRIM(params%grids_file)
      mask_filename = TRIM(params%masks_file)
      surf_filename = TRIM(params%areas_file)

      ierr = NF90_OPEN(TRIM(grid_filename), NF90_NOWRITE, il_file_id)
      cl_nam = TRIM(params%domain)//".lon"
      ierr = NF90_INQ_VARID(il_file_id, cl_nam,  il_lon_id)
      ierr = NF90_INQUIRE_VARIABLE(il_file_id, varid=il_lon_id, ndims=lon_dims, dimids=lon_dims_ids)
      DO i=1,lon_dims
         ierr = NF90_INQUIRE_DIMENSION(ncid=il_file_id,dimid=lon_dims_ids(i),len=lon_dims_len(i))
      ENDDO
      ni_glo=lon_dims_len(1)
      nj_glo=lon_dims_len(2)

      cl_nam = TRIM(params%domain)//".lat"
      ierr = NF90_INQ_VARID(il_file_id, cl_nam,  il_lat_id)
      ierr = NF90_INQUIRE_VARIABLE(il_file_id, varid=il_lat_id, ndims=lat_dims, dimids=lat_dims_ids)
      DO i=1,lat_dims
         ierr = NF90_INQUIRE_DIMENSION(ncid=il_file_id,dimid=lat_dims_ids(i),len=lat_dims_len(i))
      ENDDO
      ALLOCATE(lon_glo2D(0:ni_glo-1,0:nj_glo-1), lat_glo2D(0:ni_glo-1,0:nj_glo-1))
      ALLOCATE(ila_what(2), ila_dim(2))
      ila_what(:)=1
      ila_dim(:)=[ni_glo, nj_glo]
      ierr = NF90_GET_VAR (il_file_id, il_lon_id, lon_glo2D(0:ni_glo-1,0:nj_glo-1), ila_what, ila_dim)
      ierr = NF90_GET_VAR (il_file_id, il_lat_id, lat_glo2D(0:ni_glo-1,0:nj_glo-1), ila_what, ila_dim)
      DEALLOCATE(ila_what, ila_dim)

      cl_nam = TRIM(params%domain)//".clo"
      ierr = NF90_INQ_VARID(il_file_id, cl_nam,  il_clo_id)
      ierr = NF90_INQUIRE_VARIABLE(il_file_id, varid=il_clo_id, ndims=lon_dims, dimids=lon_dims_ids)
      DO i=1,lon_dims
         ierr = NF90_INQUIRE_DIMENSION(ncid=il_file_id,dimid=lon_dims_ids(i),len=lon_dims_len(i))
      ENDDO
      ncrn=lon_dims_len(3)

      cl_nam = TRIM(params%domain)//".cla"
      ierr = NF90_INQ_VARID(il_file_id, cl_nam,  il_cla_id)
      ierr = NF90_INQUIRE_VARIABLE(il_file_id, varid=il_lat_id, ndims=lat_dims, dimids=lat_dims_ids)
      DO i=1,lat_dims
         ierr = NF90_INQUIRE_DIMENSION(ncid=il_file_id,dimid=lat_dims_ids(i),len=lat_dims_len(i))
      ENDDO

      ALLOCATE(clo_glo2D(0:ni_glo-1,0:nj_glo-1,ncrn), cla_glo2D(0:ni_glo-1,0:nj_glo-1,ncrn))
      ALLOCATE(ila_what(3), ila_dim(3))
      ila_what(:)=1
      ila_dim(:)=[ni_glo, nj_glo, ncrn]
      ierr = NF90_GET_VAR (il_file_id, il_clo_id, clo_glo2D(0:ni_glo-1,0:nj_glo-1,1:ncrn), ila_what, ila_dim)
      ierr = NF90_GET_VAR (il_file_id, il_cla_id, cla_glo2D(0:ni_glo-1,0:nj_glo-1,1:ncrn), ila_what, ila_dim)
      DEALLOCATE(ila_what, ila_dim)

      ierr = NF90_CLOSE(il_file_id)

      ierr = NF90_OPEN(TRIM(mask_filename), NF90_NOWRITE, il_file_id)
      cl_nam = TRIM(params%domain)//".msk"
      ierr = NF90_INQ_VARID(il_file_id, cl_nam,  il_msk_id)
      ALLOCATE(msk_glo2D(0:ni_glo-1,0:nj_glo-1))
      ALLOCATE(ila_what(2), ila_dim(2))
      ila_what(:)=1
      ila_dim(:)=[ni_glo, nj_glo]
      ierr = NF90_GET_VAR (il_file_id, il_msk_id, msk_glo2D(0:ni_glo-1,0:nj_glo-1), ila_what, ila_dim)
      DEALLOCATE(ila_what, ila_dim)
      ierr = NF90_CLOSE(il_file_id)

      ierr = NF90_OPEN(TRIM(surf_filename), NF90_NOWRITE, il_file_id)
      cl_nam = TRIM(params%domain)//".srf"
      ierr = NF90_INQ_VARID(il_file_id, cl_nam,  il_srf_id)
      ALLOCATE(srf_glo2D(0:ni_glo-1,0:nj_glo-1))
      ALLOCATE(ila_what(2), ila_dim(2))
      ila_what(:)=1
      ila_dim(:)=[ni_glo, nj_glo]
      ierr = NF90_GET_VAR (il_file_id, il_srf_id, srf_glo2D(0:ni_glo-1,0:nj_glo-1), ila_what, ila_dim)
      DEALLOCATE(ila_what, ila_dim)
      ierr = NF90_CLOSE(il_file_id)

   END SUBROUTINE read_oasis_grid



   SUBROUTINE get_decomposition(comm, params, domain_proc_size, domain_proc_rank, axis_proc_size, axis_proc_rank)

      IMPLICIT NONE
      INTEGER,INTENT(IN) :: comm
      TYPE(tmodel_params) :: params
      INTEGER,INTENT(OUT) :: domain_proc_size
      INTEGER,INTENT(OUT) :: domain_proc_rank
      INTEGER,INTENT(OUT) :: axis_proc_size
      INTEGER,INTENT(OUT) :: axis_proc_rank

      INTEGER :: mpi_rank,mpi_size,rank
      INTEGER :: ierr
      INTEGER :: n_domain,n_axis, min_dist, new_dist, best
      LOGICAL :: axis_layer

      CALL MPI_COMM_RANK(comm,mpi_rank,ierr)
      CALL MPI_COMM_SIZE(comm,mpi_size,ierr)

      IF (params%axis_proc_n > 0 ) THEN
         n_axis=params%axis_proc_n
         n_domain = mpi_size / n_axis
         axis_layer=.TRUE.
      ELSE IF (params%domain_proc_n > 0 ) THEN
         n_domain=params%domain_proc_n
         n_axis = mpi_size / n_domain
         axis_layer=.FALSE.
      ELSE
         IF (params%axis_proc_frac==0) THEN
            params%axis_proc_frac=1
            params%domain_proc_frac=mpi_size
         ELSE IF (params%domain_proc_frac==0) THEN
            params%domain_proc_frac=1
            params%axis_proc_frac=mpi_size
         ENDIF

         n_domain = INT(SQRT(params%domain_proc_frac * mpi_size/ params%axis_proc_frac))
         n_axis =   INT(SQRT(params%axis_proc_frac * mpi_size/ params%domain_proc_frac))


         min_dist= mpi_size - n_domain*n_axis
         best=0

         new_dist = mpi_size -(n_domain+1)*n_axis
         IF (new_dist < min_dist .AND. new_dist >= 0 ) THEN
            min_dist=new_dist
            best=1
         ENDIF

         new_dist=mpi_size-n_domain*(n_axis+1)
         IF (new_dist < min_dist .AND. new_dist >= 0 ) THEN
            min_dist=new_dist
            best=2
         ENDIF

         IF (best==0) THEN
         ELSE IF (best==1) THEN
            n_domain=n_domain+1
         ELSE IF (best==2) THEN
            n_axis=n_axis+1
         ENDIF

         IF ( MOD(mpi_size,n_axis) <= MOD(mpi_size,n_domain)) axis_layer=.TRUE.

      ENDIF

      IF ( axis_layer) THEN
!!! n_axis layer
         IF (mpi_rank < MOD(mpi_size,n_axis)*(n_domain+1)) THEN
            axis_proc_rank=mpi_rank/(n_domain+1)
            domain_proc_rank=MOD(mpi_rank,n_domain+1)
            axis_proc_size=n_axis
            domain_proc_size=n_domain+1
         ELSE
            rank=mpi_rank-MOD(mpi_size,n_axis)*(n_domain+1)
            axis_proc_size=n_axis
            axis_proc_rank=MOD(mpi_size,n_axis)+rank/n_domain
            domain_proc_rank=MOD(rank,n_domain)
            domain_proc_size=n_domain
         ENDIF
      ELSE
!!! n_domain column
         IF (mpi_rank < MOD(mpi_size,n_domain)*(n_axis+1)) THEN
            domain_proc_rank=mpi_rank/(n_axis+1)
            axis_proc_rank=MOD(mpi_rank,n_axis+1)
            domain_proc_size=n_domain
            axis_proc_size=n_axis+1
         ELSE
            rank=mpi_rank-MOD(mpi_size,n_domain)*(n_axis+1)
            domain_proc_size=n_domain
            domain_proc_rank=MOD(mpi_size,n_domain)+rank/n_axis
            axis_proc_rank=MOD(rank,n_axis)
            axis_proc_size=n_axis
         ENDIF
      ENDIF


   END SUBROUTINE get_decomposition

END PROGRAM oasis_testcase

