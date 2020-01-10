subroutine oasis_write_grid_iso(cgrid, nx, ny, nlon1, nlon2, lon, nlat1, nlat2, lat, partid) bind(C)
  use iso_c_binding, only: c_int, c_double, c_ptr, c_bool
  use pyoasis
  use mod_oasis
  implicit none
 
  type(c_ptr), intent(in) :: cgrid     
  integer (c_int), intent (in) :: nx, ny
  integer (c_int), intent (in) :: nlon1, nlon2
  real (c_double), intent(in) :: lon(nlon1*nlon2)
  integer (c_int), intent (in) :: nlat1, nlat2
  real (c_double), intent(in) :: lat(nlat1*nlat2)
  integer(c_int), intent (in) :: partid  ! -1 if absent
  
  character(len=:), allocatable :: cgrid_f
  integer ::nx_f, ny_f
  integer :: partid_f
  cgrid_f=string_to_fortran(cgrid)
  nx_f=nx
  ny_f=ny
  partid_f=partid
  
  if(partid_f>=0) then
    call oasis_write_grid(cgrid_f, nx_f, ny_f, reshape(lon, (/nlon1, nlon2/)), reshape(lat, (/nlat1, nlat2/)), partid_f)
  else
    call oasis_write_grid(cgrid_f, nx_f, ny_f, reshape(lon, (/nlon1, nlon2/)), reshape(lat, (/nlat1, nlat2/)))
  end if
end subroutine oasis_write_grid_iso


subroutine oasis_write_corner_iso(cgrid, nx, ny, nc, nclon1, nclon2, nclon3, clon, &
                                  nclat1, nclat2, nclat3, clat, partid) bind(C)
  use iso_c_binding, only: c_int, c_double, c_ptr, c_bool
  use pyoasis
  use mod_oasis
  implicit none
  
  type(c_ptr), intent(in) :: cgrid     
  integer (c_int), intent (in) :: nx, ny, nc
  integer (c_int), intent (in) :: nclon1, nclon2, nclon3
  real (c_double), intent(in) :: clon(nclon1*nclon2*nclon3)
  integer (c_int), intent (in) :: nclat1, nclat2, nclat3
  real (c_double), intent(in) :: clat(nclat1*nclat2*nclat3)
  integer(c_int), intent (in) :: partid  ! -1 if absent
  
  character(len=:), allocatable :: cgrid_f
  integer ::nx_f, ny_f, nc_f
  integer :: partid_f
  
  cgrid_f=string_to_fortran(cgrid)
  nx_f=nx
  ny_f=ny
  nc_f=nc
  partid_f=partid  
  
  if(partid_f>=0) then
    call oasis_write_corner(cgrid_f, nx_f, ny_f, nc_f, reshape(clon, (/nclon1, nclon2, nclon3/)), &
                            reshape(clat, (/nclat1, nclat2, nclat3/)))
  else
    call oasis_write_corner(cgrid_f, nx_f, ny_f, nc_f, reshape(clon, (/nclon1, nclon2, nclon3/)), &
                            reshape(clat, (/nclat1, nclat2, nclat3/)), partid_f)
  endif

end subroutine


subroutine oasis_write_mask_iso(cgrid, nx, ny, nmask1, nmask2, mask, partid) bind(C)
  use iso_c_binding, only: c_int, c_double, c_ptr, c_bool
  use pyoasis
  use mod_oasis
  implicit none
  
  type(c_ptr), intent(in) :: cgrid     
  integer (c_int), intent (in) :: nx, ny
  integer (c_int), intent (in) :: nmask1, nmask2
  integer (c_int), intent(in) :: mask(nmask1*nmask2)
  integer(c_int), intent (in) :: partid  ! -1 if absent
  
  character(len=:), allocatable :: cgrid_f
  integer :: nx_f, ny_f
  integer :: partid_f
  
  cgrid_f=string_to_fortran(cgrid)
  nx_f=nx
  ny_f=ny
  partid_f=partid
  
  if(partid_f>=0) then
    call oasis_write_mask(cgrid_f, nx_f, ny_f, reshape(mask, (/nmask1, nmask2/)), partid_f) 
  else
    call oasis_write_mask(cgrid_f, nx_f, ny_f, reshape(mask, (/nmask1, nmask2/))) 
  end if 
end subroutine oasis_write_mask_iso
  
  
subroutine oasis_write_area_iso(cgrid, nx, ny, narea1, narea2, area, partid) bind(C)
  use iso_c_binding, only: c_int, c_double, c_ptr, c_bool
  use pyoasis
  use mod_oasis
  implicit none
 
  type(c_ptr), intent(in) :: cgrid     
  integer (c_int), intent (in) :: nx, ny
  integer (c_int), intent (in) :: narea1, narea2
  real (c_double), intent(in) :: area(narea1*narea2)
  integer(c_int), intent (in) :: partid  ! -1 if absent
  
  character(len=:), allocatable :: cgrid_f
  integer :: nx_f, ny_f
  integer :: partid_f
  
  cgrid_f=string_to_fortran(cgrid)
  nx_f=nx
  ny_f=ny
  partid_f=partid
  
  if(partid_f>=0) then
    call oasis_write_area(cgrid_f, nx_f, ny_f, reshape(area, (/narea1, narea2/)), partid_f)
  else
    call oasis_write_area(cgrid_f, nx_f, ny_f, reshape(area, (/narea1, narea2/)))
  end if
end subroutine oasis_write_area_iso


subroutine oasis_terminate_grids_writing_iso() bind(C)
  use iso_c_binding
  use pyoasis
  use mod_oasis
  implicit none
  call oasis_terminate_grids_writing()
end subroutine oasis_terminate_grids_writing_iso
