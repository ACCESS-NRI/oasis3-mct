MODULE function_ana
!
  IMPLICIT NONE
!
  CONTAINS
!
!****************************************************************************************
SUBROUTINE function_sinusoid(ni, nj, xcoor, ycoor, fnc_ana)
!****************************************************************************************

!**** *function ana*  - calculate analytical function

  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double

  INTEGER, INTENT(IN) :: ni, nj
  REAL(kind=wp), DIMENSION(ni,nj), INTENT(IN)  :: xcoor, ycoor
  REAL(kind=wp), DIMENSION(ni,nj), INTENT(OUT) :: fnc_ana

  REAL (kind=wp), PARAMETER    :: dp_pi=3.14159265359
  REAL (kind=wp), PARAMETER    :: dp_conv = dp_pi/180.
  REAL(kind=wp)  :: dp_length, coef, coefmult
  INTEGER             :: i,j
  CHARACTER(LEN=7) :: cl_anaftype="fcos"

  DO j=1,nj
    DO i=1,ni

      SELECT CASE (cl_anaftype)
      CASE ("fcos")
        dp_length = 1.2*dp_pi
        coef = 2.
        coefmult = 1.
        fnc_ana(i,j) = coefmult*(coef - COS( dp_pi*(ACOS( COS(xcoor(i,j)*dp_conv)*COS(ycoor(i,j)*dp_conv) )/dp_length)) )

      CASE ("fcossin")
        dp_length = 1.d0*dp_pi
        coef = 21.d0
        coefmult = 3.846d0 * 20.d0
        fnc_ana(i,j) = coefmult*(coef - COS( dp_pi*(ACOS( COS(ycoor(i,j)*dp_conv)*COS(ycoor(i,j)*dp_conv) )/dp_length)) * &
                                        SIN( dp_pi*(ASIN( SIN(xcoor(i,j)*dp_conv)*SIN(ycoor(i,j)*dp_conv) )/dp_length)) )
      END SELECT

    ENDDO
  ENDDO

END SUBROUTINE function_sinusoid

!!****************************************************************************************
!SUBROUTINE function_gulfstream(lon, lat, mask, fnc_ana)
SUBROUTINE function_gulfstream(ni, nj, lon, lat, fnc_ana)
!!****************************************************************************************

!**** *function ana*  - calculate analytical function

  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double

  INTEGER, INTENT(IN) :: ni, nj
  REAL (kind=wp), DIMENSION(ni,nj), INTENT(IN)  :: lon, lat
  REAL(kind=wp), DIMENSION(ni,nj), INTENT(OUT) :: fnc_ana

  REAL (kind=wp), PARAMETER :: coef=2., dp_pi=3.14159265359
  REAL (kind=wp) :: dp_length, dp_conv
  INTEGER :: i, j

  ! Analytical Gulf Stream
  REAL (kind=wp) :: gf_coef, gf_ori_lon, gf_ori_lat, &
                  & gf_end_lon, gf_end_lat, gf_dmp_lon, gf_dmp_lat
  REAL (kind=wp) :: gf_per_lon 
  REAL (kind=wp) :: dx, dy, dr, dth, dc, dr0, dr1

  ! Parameters for analytical function
  dp_length = 1.2*dp_pi
  dp_conv = dp_pi/180.
  gf_coef = 1.0 ! Coefficient for Gulf Stream term (0.0 = no Gulf Stream)
  gf_ori_lon = -80.0 ! Origin of the Gulf Stream (longitude in deg)
  gf_ori_lat =  25.0 ! Origin of the Gulf Stream (latitude in deg) 
  gf_end_lon =  -1.8 ! End point of the Gulf Stream (longitude in deg)
  gf_end_lat =  50.0 ! End point of the Gulf Stream (latitude in deg) 
  gf_dmp_lon = -25.5 ! Point of the Gulf Stream decrease (longitude in deg)
  gf_dmp_lat =  55.5 ! Point of the Gulf Stream decrease (latitude in deg) 

!  ALLOCATE(fnc_ana(0:xy-1))

  dr0 = SQRT(((gf_end_lon - gf_ori_lon)*dp_conv)**2 + &
     & ((gf_end_lat - gf_ori_lat)*dp_conv)**2)
  dr1 = SQRT(((gf_dmp_lon - gf_ori_lon)*dp_conv)**2 + &
     & ((gf_dmp_lat - gf_ori_lat)*dp_conv)**2)

  DO j=1,nj
    DO i=1,ni

      ! Original OASIS fcos analytical test function
      fnc_ana(i,j)=(coef-COS(dp_pi*(ACOS(COS(lat(i,j)*dp_conv)*&
                       & COS(lon(i,j)*dp_conv))/dp_length)))
      gf_per_lon = lon(i,j)
      IF (gf_per_lon > 180.0) gf_per_lon = gf_per_lon - 360.0
      IF (gf_per_lon < -180.0) gf_per_lon = gf_per_lon + 360.0 
      dx = (gf_per_lon - gf_ori_lon)*dp_conv
      dy = (lat(i,j) - gf_ori_lat)*dp_conv
      dr = SQRT(dx*dx + dy*dy)
      dth = ATAN2(dy, dx)
      dc = 1.3*gf_coef
      IF (dr > dr0) dc = 0.0
      IF (dr > dr1) dc = dc * COS(dp_pi*0.5*(dr-dr1)/(dr0-dr1))
      fnc_ana(i,j) = fnc_ana(i,j) + &
                       & (MAX(1000.0*SIN(0.4*(0.5*dr+dth) + &
                       &  0.007*COS(50.0*dth) + 0.37*dp_pi),999.0) - 999.0) * dc

    ENDDO
  ENDDO

END SUBROUTINE function_gulfstream

!****************************************************************************************
SUBROUTINE function_vortex(ni, nj, xcoor, ycoor, fnc_ana)
!**************************************************************************************** 
!!! VORTEX FROM TEMPEST-REMAP (as in XIOS)
  !
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double
  !
  INTEGER, INTENT(IN) :: ni, nj
  REAL(kind=wp), DIMENSION(ni,nj), INTENT(IN)  :: xcoor, ycoor
  REAL(kind=wp), DIMENSION(ni,nj), INTENT(OUT) :: fnc_ana

  REAL(kind=wp), PARAMETER :: dp_pi = 3.14159265359
  REAL(kind=wp), PARAMETER :: dLon0 = 5.5
  REAL(kind=wp), PARAMETER :: dLat0 = 0.2
  REAL(kind=wp), PARAMETER :: dR0   = 3.0
  REAL(kind=wp), PARAMETER :: dD    = 5.0
  REAL(kind=wp), PARAMETER :: dT    = 6.0
  REAL(kind=wp) :: dp_length, dp_conv

  REAL(kind=wp) :: dSinC, dCosC, dCosT, dSinT
  REAL(kind=wp) :: dTrm, dX, dY, dZ
  REAL(kind=wp) :: dlon, dlat
  REAL(kind=wp) :: dRho, dVt, dOmega

  INTEGER          :: i,j
  CHARACTER(LEN=7) :: cl_anaftype="vortex"

  dp_conv = dp_pi/180.
  dSinC = SIN( dLat0 )
  dCosC = COS( dLat0 )

  DO j=1,nj
     DO i=1,ni
        ! Find the rotated longitude and latitude of a point on a sphere
        !		with pole at (dLon0, dLat0).
        dCosT = COS( ycoor(i,j)*dp_conv )
        dSinT = SIN( ycoor(i,j)*dp_conv )
        
        dTrm = dCosT * COS( xcoor(i,j)*dp_conv - dLon0 )
        dX   = dSinC * dTrm - dCosC * dSinT
        dY   = dCosT * SIN( xcoor(i,j)*dp_conv - dLon0 )
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
        
        fnc_ana(i,j) = 2.0 * ( 1.0 + TANH( dRho / dD * SIN( dLon - dOmega * dT ) ) )
        
     END DO
  END DO
  !
END SUBROUTINE function_vortex

!****************************************************************************************
SUBROUTINE function_harmonic(ni, nj, xcoor, ycoor, fnc_ana)
!****************************************************************************************
!!! HARMONIC FROM TEMPEST-REMAP
  !
  IMPLICIT NONE
  !
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double
  !
  INTEGER, INTENT(IN) :: ni, nj
  REAL(kind=wp), DIMENSION(ni,nj), INTENT(IN)  :: xcoor, ycoor
  REAL(kind=wp), DIMENSION(ni,nj), INTENT(OUT) :: fnc_ana
  !
  REAL (kind=wp), PARAMETER    :: dp_pi=3.14159265359
  REAL (kind=wp), PARAMETER    :: dp_conv = dp_pi/180.
  !
  INTEGER             :: i,j
  !
  DO j=1,nj
     DO i=1,ni
        fnc_ana(i,j) = 2.0 + SIN( 2.0 * ycoor(i,j)*dp_conv ) ** 16.0  * COS( 16.0 * xcoor(i,j)*dp_conv )
    ENDDO
 ENDDO
END SUBROUTINE function_harmonic

END MODULE function_ana
