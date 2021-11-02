SUBROUTINE gradient_conserv(NX1, NY1, ibeg, jbeg, iloc, jloc, &
                         cl_grd_src, id_per, cd_per, w_unit, &
                         local_grad_lon, local_grad_lat, file_debug)

!
!**** *gradient_conserv*  - calculate gradients for conservative remapping
!
!     Purpose:
!     -------
!     Calculation of gradients in latitudinal and longitudinal direction.
!     In a first step the gradients in direction of source-grid rows  
!     and lines are calculated. Then they are rotated to longitudinal 
!     and latitudinal direction, using the scalar product.
!     This routine works for logically rectangular grids, only.
!
!**   Interface:
!     ---------
!       *CALL*  *gradient_conserv*(NX1, NY1, jbeg, iloc, jloc,
!                                  cl_grd_src, id_per, cd_per, w_unit,
!                                  local_grad_lat, local_grad_lon, file_debug)
!
!     Input:
!     -----
!          NX1            : grid global dimension in x-direction (integer)
!          NY1            : grid global dimension in y-direction (integer)
!          ibeg           : start of local domain in global domain in x-direction
!          jbeg           : start of local domain in global domain in y-direction
!          iloc           : grid local dimension in x-direction (integer)
!          jloc           : grid local dimension in y-direction (integer)
!          cl_grd_src     : grid acronym
!          id_per         : number of overlapping points for source grid
!          cd_per         : grip periodicity type
!          w_unit         : log file unit
!          file_debug     : logical for activating debug outputs
! 
!     Output:
!     ------
!          local_grad_lon       : gradient in longitudinal direction (real 2D)
!          local_grad_lat       : gradient in latitudinal direction (real 2D)
!
! %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!
      USE read_all_data
      USE function_ana
!
      IMPLICIT NONE

      INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double
!-----------------------------------------------------------------------
!      INTENT(IN)
!-----------------------------------------------------------------------
      INTEGER, INTENT(IN) :: &
          NX1, NY1,  &         ! source grid dimensions
         ibeg, jbeg, &         ! source grid local start
         iloc, jloc            ! source grid local dimensions

      CHARACTER(len=4), INTENT(IN) ::  &
         cl_grd_src            ! grid acronym

      INTEGER, INTENT(IN) :: &
          id_per,      &       ! nbr of overlapping grid points
          w_unit               ! log file
  
      CHARACTER*8, INTENT(IN) :: &
          cd_per                ! grip periodicity type     

      LOGICAL, INTENT(IN)      :: file_debug

!-----------------------------------------------------------------------
!     INTENT(OUT)
!-----------------------------------------------------------------------
      REAL (kind=wp), DIMENSION(iloc,jloc), INTENT(OUT) :: &
           local_grad_lon, &             ! gradient in longitudinal direction
           local_grad_lat                ! gradient in latitudinal direction

!-----------------------------------------------------------------------
!     LOCAL VARIABLES
!-----------------------------------------------------------------------
      INTEGER :: &
           i, j, &                ! looping indicees
           ip1, jp1, im1, jm1, iend, jend

      REAL (kind=wp) :: &
           distance_rad           ! distance in rad
     
      REAL (kind=wp) :: &
           dVar_i, dVar_j, &      ! difference of Var in i / j direction
           dlat_i, dlat_j, &      ! difference in lat in i / j direction
           dlon_i, dlon_j, &      ! difference in lon in i / j direction
           dist_i, dist_j, &      ! distance in i / j direction
           grad_i, grad_j, &      ! gradient in i / j direction
           ABSold, ABSnew, lat_factor

      REAL (kind=wp), DIMENSION(:,:), POINTER :: &
           src_lon, &             ! source grid longitudes [radiants]
           src_lat, &             ! source grid latitudes [radiants]
           src_array, &           ! analytical field
           grad_lon, &            ! global gradient in latitudinal direction
           grad_lat               ! global gradient in longitudinal direction

      INTEGER, DIMENSION(:,:), POINTER :: &
           sou_mask             ! source grid mask

      REAL (kind=wp), PARAMETER :: &
           pi  = 3.14159265358979323846, &  ! PI
           pi2 = 2.0d0*pi, &                ! 2PI
           pi180  = 1.74532925199432957692e-2 ! =PI/180

      INTEGER, PARAMETER ::  il_maskval= 1 ! in our grids sea_value = 0 and land_value = 1

!-----------------------------------------------------------------------
!
!     Read global grid and global mask
!     --------------------------------
      ALLOCATE(src_lon(NX1, NY1))
      ALLOCATE(src_lat(NX1, NY1))
      CALL read_grid(NX1, NY1, 1, 1, NX1, NY1, cl_grd_src, w_unit, src_lon, src_lat, file_debug)
!
      ALLOCATE(sou_mask(NX1, NY1))
      CALL read_mask(NX1, NY1, 1, 1, NX1, NY1, cl_grd_src, w_unit, sou_mask, file_debug)

!     Global field from analytical function
!     -------------------------------------
      ALLOCATE(src_array(NX1, NY1))
#ifdef FANA1
      CALL function_ana1(NX1, NY1, src_lon, src_lat, src_array)
#elif defined FANA2
      CALL function_ana2(NX1, NY1, src_lon, src_lat, src_array)
#elif defined FANA3
      CALL function_ana3(NX1, NY1, src_lon, src_lat, src_array)
#endif

!     Global gradient allocation
!     --------------------------
      ALLOCATE(grad_lon(NX1, NY1))
      ALLOCATE(grad_lat(NX1, NY1))

!     Initialization
!     --------------
      grad_lon  = 0.
      grad_lat  = 0.

!     transformation in radiants for gradient calculation
!     ---------------------------------------------------
      src_lon = src_lon * pi180
      src_lat = src_lat * pi180 

!     calculate gradients
!     -------------------
      DO i = 1, NX1
         DO j = 1, NY1
                   
            IF (sou_mask(i,j) /= il_maskval) THEN

               ip1 = i + 1
               im1 = i - 1
               IF (i == NX1) THEN
                   IF (cd_per == 'P') ip1 = 1 + id_per ! the 0-meridian
                   IF (cd_per == 'R') ip1 = NX1
               ENDIF
               IF (i == 1 )  THEN
                   IF (cd_per == 'P') im1 = NX1 - id_per
                   IF (cd_per == 'R') im1 = 1
               ENDIF
               jp1 = j + 1
               jm1 = j - 1
               IF (j == NY1) jp1 = NY1 ! treatment of the last..
               IF (j == 1 )  jm1 = 1   ! .. and the first grid-row

               IF (sou_mask(ip1,j) == il_maskval)  ip1 = i
               IF (sou_mask(im1,j) == il_maskval)  im1 = i
               IF (sou_mask(i,jp1) == il_maskval)  jp1 = j
               IF (sou_mask(i,jm1) == il_maskval)  jm1 = j          

!              difference between neighbouring datapoints
               dVar_i = src_array(ip1,j) - src_array(im1,j)
               dVar_j = src_array(i,jp1) - src_array(i,jm1)

!              difference in latitudes
               dlat_i = src_lat(ip1,j) - src_lat(im1,j)
               dlat_j = src_lat(i,jp1) - src_lat(i,jm1)

!              difference in longitudes
               dlon_i = src_lon(ip1,j) - src_lon(im1,j)
               IF (dlon_i > pi)  dlon_i = dlon_i - pi2
               IF (dlon_i < (-pi)) dlon_i = dlon_i + pi2
               dlon_j = src_lon(i,jp1) - src_lon(i,jm1)
               IF (dlon_j >   pi)  dlon_j = dlon_j - pi2
               IF (dlon_j < (-pi)) dlon_j = dlon_j + pi2
               lat_factor = COS(src_lat(i,j))
               dlon_i = dlon_i * lat_factor
               dlon_j = dlon_j * lat_factor
 
!              distance
               dist_i = distance_rad(src_lon(ip1,j), src_lat(ip1,j), &
                                     src_lon(im1,j), src_lat(im1,j))
               dist_j = distance_rad(src_lon(i,jp1), src_lat(i,jp1), &
                                     src_lon(i,jm1), src_lat(i,jm1))

!              gradients: dVar / distance (= vector lenght)
               IF (dist_i /= 0.) THEN
                  grad_i = dVar_i / dist_i
               ELSE
                  grad_i = 0
               ENDIF
               IF (dist_j /= 0.) THEN
                  grad_j = dVar_j / dist_j
               ELSE
                  grad_j = 0
               ENDIF

!              projection by scalar product
!              ----------------------------
               grad_lon(i,j) = grad_i * dlon_i + grad_j * dlat_i
               grad_lat(i,j) = grad_i * dlon_j + grad_j * dlat_j

               IF (dist_i /= 0) then
                  grad_lon(i,j) = grad_lon(i,j) / dist_i
               ELSE
                  grad_lon(i,j) = 0
               ENDIF
               IF (dist_j /= 0) then
                  grad_lat(i,j) = grad_lat(i,j) / dist_j
               ELSE
                  grad_lat(i,j) = 0.
               ENDIF
              
!              correct skale
!              -------------
               ABSold = SQRT(grad_i**2 + grad_j**2)
               ABSnew = SQRT(grad_lon(i,j)**2 + grad_lat(i,j)**2)
               IF (ABSnew > 1.E-10) THEN
!                  grad_lon(i,j) = grad_lon(i,j)*ABSold/ABSnew
                  grad_lon(i,j) = grad_lon(i,j)
               ELSE
                  grad_lon(i,j) = 0.0
               ENDIF

!              test orthogonality
!              ------------------
               IF ((dlon_i*dlon_j+dlat_j*dlat_i) > 0.1) THEN
                  print*, 'ORTHOGONAL? ', i, j, (dlon_i*dlon_j+dlat_j*dlat_i)
               ENDIF

            ELSE
           
               grad_lat(i,j) = 0.
               grad_lon(i,j) = 0. 
            
            ENDIF

         ENDDO
      ENDDO
      !
      iend = ibeg+iloc-1
      jend = jbeg+jloc-1
      local_grad_lat = grad_lat(ibeg:iend, jbeg:jend)
      local_grad_lon = grad_lon(ibeg:iend, jbeg:jend)

END SUBROUTINE gradient_conserv
