subroutine gradient_bicubic(NX1, NY1, ibeg, jbeg, iloc, jloc, &
                            cl_grd_src, id_per, cd_per, w_unit, &
                            local_gradient_i, local_gradient_j, local_gradient_ij, file_debug)
!
!**** *gradient_bicubic*  - calculate gradients for bicubic remapping
!
!     Purpose:
!     -------
!     Calculation of gradients for bicubic interpolation. In contrast to
!     the gradients of conservative remapping, these gradients are    
!     calculated with respect to grid rows and grid lines.
!
!**   Interface:
!     ---------
!       *CALL*  *gradient_bicubic*(NX1, NY1, ibeg, jbeg, iloc, jloc, 
!                                  cl_grd_src, id_per, cd_per, w_unit,
!                                  local_gradient_i, local_gradient_j, local_gradient_ij, file_debug)
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
!          local_gradient_i     : gradient in i-direction (real 2D)
!          local_gradient_j     : gradient in j-direction (real 2D)
!          local_gradient_ij    : gradient in ij-direction (real 2D)
!
! %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
!
USE read_all_data
USE function_ana
!
IMPLICIT NONE
      
INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double
!-----------------------------------------------------------------------
!     INTENT(IN)
!-----------------------------------------------------------------------
INTEGER, INTENT(IN) :: &
         NX1, NY1,  &          ! source grid global dimensions
         ibeg, jbeg, &         ! source grid local start
         iloc, jloc            ! source grid local dimensions

CHARACTER(len=4), INTENT(IN) ::  &
         cl_grd_src            ! grid acronym

INTEGER, INTENT(IN) :: &
         id_per, &             ! nbr of overlapping grid points
         w_unit                ! log file 

CHARACTER(len=8), INTENT(IN) ::  &
         cd_per                ! grip periodicity type 

LOGICAL, INTENT(IN)      :: file_debug
!
!-----------------------------------------------------------------------
!     INTENT(OUT)
!-----------------------------------------------------------------------
REAL (kind=wp), DIMENSION(iloc, jloc), INTENT(OUT) :: &
          local_gradient_i,   &       ! gradient in i-direction (real 2D)
          local_gradient_j,   &       ! gradient in j-direction (real 2D)
          local_gradient_ij           ! gradient in ij-direction (real 2D)

!-----------------------------------------------------------------------
!     LOCAL VARIABLES
!-----------------------------------------------------------------------
INTEGER ::  &
          i, j,    &            ! looping indicees
          ip1, jp1, im1, jm1, iend, jend
     
REAL (kind=wp) ::  &
          di, dj,        &         ! factor depending on grid cell distance
          gradient_ij1,  &         ! gradient needed to calculate gradient_ij
          gradient_ij2             ! gradient needed to calculate gradient_ij

REAL (kind=wp), DIMENSION(:,:), POINTER :: &
          src_lon,   &          ! source grid longitudes [radiants]
          src_lat,   &          ! source grid latitudes [radiants]
          src_array, &          ! analytical field
          gradient_i, &  ! global gradient in i-direction (real 2D)
          gradient_j, &  ! global gradient in j-direction (real 2D)
          gradient_ij    ! global gradient in ij-direction (real 2D)

INTEGER, DIMENSION(:,:), POINTER :: &
         sou_mask             ! source grid mask 

INTEGER, PARAMETER ::  il_maskval= 1 ! in our grids sea_value = 0 and land_value = 1

!----------------------------------------------------------------------
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
#ifdef Fsinusoid
      CALL function_sinusoid(NX1, NY1, src_lon, src_lat, src_array)
#elif defined Fgulfstream
      CALL function_gulfstream(NX1, NY1, src_lon, src_lat, src_array)
#elif defined Fvortex
      CALL function_vortex(NX1, NY1, src_lon, src_lat, src_array)
#elif defined Fharmonic
      CALL function_harmonic(NX1, NY1, src_lon, src_lat, src_array)
#endif

!     Global gradient allocation
!     --------------------------
      ALLOCATE(gradient_i(NX1, NY1))
      ALLOCATE(gradient_j(NX1, NY1))
      ALLOCATE(gradient_ij(NX1, NY1))

!     Initialization
!     --------------
      gradient_i  = 0.
      gradient_j  = 0. 
      gradient_ij = 0. 

!     calculate gradients
!     -------------------
      DO i = 1, NX1
         DO j = 1, NY1
                   
            IF (sou_mask (i,j) /= il_maskval) THEN

               di = 0.5
               dj = 0.5

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
               IF (j == NY1) THEN ! treatment of the last..
                  jp1 = NY1 
                  dj = 1.
               ENDIF   
               IF (j == 1 ) THEN  ! .. and the first grid-row
                  jm1 = 1
                  dj = 1.
               ENDIF


!              gradient i
!              ----------
               IF (sou_mask(ip1,j) /= il_maskval .OR. &
                   sou_mask(im1,j) /= il_maskval) THEN
                  IF (sou_mask(ip1,j) == il_maskval) THEN
                     ip1 = i
                     di = 1.
                  ELSE IF (sou_mask(im1,j) == il_maskval) THEN
                     im1 = i
                     di = 1.
                  ENDIF
                  gradient_i(i,j) = di * (src_array(ip1,j) - src_array(im1,j))
               ENDIF

!              gradient j
!              ----------
               IF (sou_mask(i,jp1) /= il_maskval .OR. &
                   sou_mask(i,jm1) /= il_maskval) THEN
                  IF (sou_mask(i,jp1) == il_maskval) THEN
                     jp1 = j
                     dj = 1.
                  ELSE IF (sou_mask(i,jm1) == il_maskval) THEN
                     jm1 = j
                     dj = 1.
                  ENDIF
                  gradient_j(i,j) = dj * (src_array(i,jp1) - src_array(i,jm1))
               ENDIF
!
!              gradient ij
!              -----------
               di = 0.5
               dj = 0.5
               ip1 = i + 1
               im1 = i - 1
               IF (i == NX1) THEN
                   IF (cd_per == 'P') ip1 = 1 + id_per ! the 0-meridian
                   IF (cd_per == 'R') ip1 = NX1
               ENDIF
               IF (i == 1 )  THEN
                   IF (cd_per == 'P')  im1 = NX1 - id_per
                   IF (cd_per == 'R')  im1 = 1
               ENDIF
               jp1 = j + 1
               jm1 = j - 1
               IF (j == NY1) THEN ! treatment of the last..
                  jp1 = NY1 
                  dj = 1.
               ENDIF   
               IF (j == 1 ) THEN  ! .. and the first grid-row
                  jm1 = 1
                  dj = 1.
               ENDIF

               gradient_ij1 = 0.
               IF (sou_mask(ip1,jp1) /= il_maskval .OR. &
                   sou_mask(im1,jp1) /= il_maskval) THEN
                  IF (sou_mask(ip1,jp1) == il_maskval .AND. &
                      sou_mask(i,jp1) /= il_maskval) THEN
                     ip1 = i
                     di = 1.
                  ELSE IF (sou_mask(im1,jp1) == il_maskval .AND. &
                           sou_mask(i,jp1) /= il_maskval) THEN
                     im1 = i
                     di = 1.
                  ELSE
                     di = 0.
                  ENDIF
                  gradient_ij1 = di * (src_array(ip1,jp1) - src_array(im1,jp1))
               ENDIF

               di = 0.5
               ip1 = i + 1
               im1 = i - 1
               IF (i == NX1) THEN
                   IF (cd_per == 'P') ip1 = 1 + id_per ! the 0-meridian
                   IF (cd_per == 'R') ip1 = NX1
               ENDIF
               IF (i == 1)  THEN
                   IF (cd_per == 'P') im1 = NX1 - id_per
                   IF (cd_per == 'R') im1 = 1
               ENDIF
               gradient_ij2 = 0.
               IF (sou_mask(ip1,jm1) /= il_maskval .OR. &
                   sou_mask(im1,jm1) /= il_maskval) THEN
                  IF (sou_mask(ip1,jm1) == il_maskval .AND. &
                      sou_mask(i,jm1) /= il_maskval) THEN
                     ip1 = i
                     di = 1.
                  ELSE IF (sou_mask(im1,jm1) == il_maskval .AND. &
                          sou_mask(i,jm1) /= il_maskval) THEN
                     im1 = i
                     di = 1.
                  ELSE
                     di = 0.
                  ENDIF
                  gradient_ij2 = di * (src_array(ip1,jm1) - src_array(im1,jm1))
               ENDIF

               IF (gradient_ij1 /= 0. .AND. gradient_ij2 /= 0.) THEN
                  gradient_ij(i,j) = dj * (gradient_ij1 - gradient_ij2)
               ENDIF
            ENDIF
            
         ENDDO
      ENDDO
      !
      iend = ibeg+iloc-1
      jend = jbeg+jloc-1
      local_gradient_i = gradient_i(ibeg:iend, jbeg:jend)
      local_gradient_j = gradient_j(ibeg:iend, jbeg:jend)
      local_gradient_ij = gradient_ij(ibeg:iend, jbeg:jend)
!
END SUBROUTINE gradient_bicubic
