subroutine oasis_def_partition_iso(id_part, kparal, kinfo, ig_size, name) bind(C)
  use iso_c_binding, only: c_int, c_ptr
  use pyoasis
  use mod_oasis
  implicit none
  integer (c_int), intent(out) :: id_part
  integer (c_int), dimension(:), intent(in) :: kparal
  integer (c_int), intent(out) :: kinfo
  integer (c_int), intent(in) :: ig_size
  type(c_ptr), intent(in) :: name
  
  integer :: id_part_f
  integer, dimension(size(kparal)) :: kparal_f
  integer :: kinfo_f
  integer :: ig_size_f
  character(len=:), allocatable :: name_f
  
  integer :: i
  do i=1, size(kparal)
    kparal_f(i)=kparal(i)
  end do
  ig_size_f=ig_size
  name_f=string_to_fortran(name)
  
  call oasis_def_partition(id_part_f, kparal_f, kinfo_f, ig_size_f, name_f)

  id_part=id_part_f
  kinfo=kinfo_f
end subroutine oasis_def_partition_iso


