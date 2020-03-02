subroutine oasis_def_partition_iso(id_part, n, parameters, kinfo) bind(C)
  use iso_c_binding, only: c_int, c_ptr
  use pyoasis
  use mod_oasis
  implicit none
  integer (c_int), intent(out) :: id_part
  integer (c_int), intent(in) :: n
  integer (c_int), intent(in), dimension(n) :: parameters
  integer (c_int), intent(out) :: kinfo

  integer :: id_part_f
  integer :: kinfo_f
  character(len=:), allocatable :: name_f
  
  integer :: i

call oasis_def_partition(id_part_f, parameters, kinfo_f)
  id_part=id_part_f
  
  kinfo=kinfo_f
end subroutine oasis_def_partition_iso


