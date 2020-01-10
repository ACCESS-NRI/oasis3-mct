subroutine oasis_put_iso(var_id, &
                         kstep, &
                         n_dimensions, &
                         sizes, &
                         field, &
                         kinfo) bind(C)
                             
  use iso_c_binding, only: c_int, c_double, c_ptr, c_bool
  use pyoasis
  use mod_oasis
  use mod_oasis_getput_interface
  
  use mod_oasis_kinds
  use mod_oasis_data
  use mod_oasis_parameters
  use mod_oasis_advance
  use mod_oasis_var
  use mod_oasis_sys
  use mct_mod
  
  implicit none

  integer (c_int), intent(in) :: var_id
  integer (c_int), intent(in) :: kstep
  integer (c_int), intent(in) :: n_dimensions
  integer (c_int), intent(in) :: sizes(n_dimensions)
  real (c_double), intent(in) :: field(product(sizes))
  integer (c_int), intent(out) :: kinfo
  
  integer :: var_id_f
  integer :: kstep_f
  integer :: kinfo_f
  integer :: sizes2(2)
  integer :: sizes3(3) 
  
  var_id_f=var_id
  kstep_f=kstep

  select case (n_dimensions)
    case(1)
      call oasis_put(var_id_f, kstep_f, field, kinfo_f)
    case(2)
      sizes2=sizes
      call oasis_put(var_id_f, kstep_f, reshape(field, sizes2), kinfo_f)
    case(3)
      sizes3=sizes
      call oasis_put(var_id_f, kstep_f, reshape(field, sizes3), kinfo_f)
  end select
  
  kinfo=kinfo_f
end subroutine oasis_put_iso



subroutine oasis_get_iso(var_id, kstep, n_dimensions, sizes, field, kinfo) bind(C)
  use iso_c_binding, only: c_int, c_double, c_ptr, c_bool
  use pyoasis
  use mod_oasis
  use mod_oasis_getput_interface
  use mod_oasis_kinds
  use mod_oasis_data
  use mod_oasis_parameters
  use mod_oasis_advance
  use mod_oasis_var
  use mod_oasis_sys
  use mct_mod 
  implicit none
  
  integer (c_int), intent(in) :: var_id
  integer (c_int), intent(in) :: kstep
  integer (c_int), intent(in) :: n_dimensions
  integer (c_int), intent(in) :: sizes(:)
  real (c_double), intent(inout) :: field(:)
  integer(c_int) , intent(out):: kinfo
  
  integer :: var_id_f
  integer :: kstep_f
  integer :: kinfo_f
  integer :: sizes2(2)
  integer :: sizes3(3)
  real, allocatable :: field2(:,:)
  real, allocatable :: field3(:,:,:)
  
  var_id_f=var_id
  kstep_f=kstep

  select case (n_dimensions)
    case(1)
      call oasis_get(var_id_f, kstep_f, field, kinfo_f)
    case(2)
      sizes2=sizes
      field2=reshape(field, sizes2)
      call oasis_get(var_id_f, kstep_f, field2, kinfo_f)
    case(3)
      sizes3=sizes
      field3=reshape(field, sizes3)
      call oasis_get(var_id_f, kstep_f, field3, kinfo_f)
  end select
  
  kinfo=kinfo_f
  
end subroutine oasis_get_iso
