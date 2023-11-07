
!> OASIS map (interpolation) weight generation with YAC. Data and methods

MODULE mod_oasis_yac_map

   USE mod_oasis_kinds
   USE mod_oasis_data
   USE mod_oasis_namcouple
   USE mod_oasis_map, ONLY: prism_mapper
   USE mod_oasis_sys, ONLY: oasis_debug_enter, oasis_debug_exit
   USE mod_oasis_timer, ONLY: oasis_timer_start, oasis_timer_stop

#ifdef YAC_REMAP
   USE, INTRINSIC :: iso_c_binding

   ! Access to the YAC core utilities and definitions and to the remap toolbox
   USE mo_yac_core
   USE mo_yac_utils, ONLY : yac_free_c, &
      & yac_read_scrip_basic_grid_parallel_c, &
      & yac_duplicate_stencils_c

   IMPLICIT NONE

   PRIVATE

   PUBLIC oasis_map_yac_init, oasis_map_yac_genmap, oasis_map_yac_free

   INTERFACE

      !> Low level C function access for setting an environment variable from F90
      !! param [in] name the name of the variable
      !! param [in] val  the value to be set (always as a string)
      !! param [in] overwrite  toggle value overwriting (0 false, 1 true)
      FUNCTION setenv_c(name,val,overwrite) &
         BIND ( C, name='setenv' )

         USE, INTRINSIC :: iso_c_binding

         CHARACTER(kind=c_char), DIMENSION(*) :: name
         CHARACTER(kind=c_char), DIMENSION(*) :: val
         INTEGER(kind=c_int), VALUE           :: overwrite

         INTEGER(kind=c_int) :: setenv_c
      END FUNCTION setenv_c

   END INTERFACE

   ! Define YAC internal types

   !> Storage of YAC grid structures
   TYPE, PRIVATE :: yac_grid_f
      CHARACTER(LEN=:), ALLOCATABLE :: id            !< identifier of the grid
      CHARACTER(LEN=:), ALLOCATABLE :: grid_filename !< grid file name
      CHARACTER(LEN=:), ALLOCATABLE :: mask_filename !< mask file name
      TYPE(c_ptr) :: grid                       !< ptr to YAC grid structure (C)
      TYPE(c_ptr) :: duplicated_cell_idx        !< ptr to YAC array of duplicated cells
      TYPE(c_ptr) :: orig_cell_global_id        !< ptr to YAC array of the origin of dupl. cells
      INTEGER(c_size_t) :: nbr_duplicated_cells !< number of duplicated cells
      INTEGER(c_size_t) :: grid_size            !< total size of the grid
   END TYPE yac_grid_f

   !> Storage of YAC distributed grid pairs structures
   TYPE, PRIVATE ::  yac_dist_grid_pair_f
      TYPE(c_ptr) :: pair  !< ptr to YAC distributed grid pair structure (C)
      INTEGER :: grids(2)  !< indexes of the two associated basic grids
   END TYPE yac_dist_grid_pair_f

   ! Accessible encapsulated collections

   !> Collection of basic grids
   TYPE basic_grid_collection
      INTEGER, PRIVATE :: num_basic_grids               !< size of the collection
      INTEGER(kind=YAC_MPI_FINT_KIND), PRIVATE :: comm  !< local MPI communicator
      TYPE(yac_grid_f), DIMENSION(:), &
         & ALLOCATABLE, PRIVATE :: grids !< array of basic grid types
   CONTAINS
      PROCEDURE, PUBLIC :: init => bg_init !< initialization
      PROCEDURE, PUBLIC :: get => bg_get   !< recover index if stored or read from file
      PROCEDURE, PUBLIC :: id => bg_id     !< get the grid name
      PROCEDURE, PUBLIC :: grid_size => bg_grid_size !< get the grid size
      PROCEDURE, PUBLIC :: grid => bg_grid !< give F90 access to a grid structure
      PROCEDURE, PUBLIC :: orig_cell_global_id => bg_orig_cell_global_id !< get the index of ref
                                                                  !! cells for duplicated entries
      PROCEDURE, PUBLIC :: duplicated_cell_idx => bg_duplicated_cell_idx !< get the index of
                                                                         !! duplicated cells
      PROCEDURE, PUBLIC :: nbr_duplicated_cells => bg_nbr_duplicated_cells !< get the number of
                                                                           !!duplicated cells
      PROCEDURE, PUBLIC :: free => bg_free !< finalization
   END TYPE basic_grid_collection

   !> Collection of distributed grid pairs
   TYPE dist_grid_pair_collection
      INTEGER, PRIVATE :: num_dist_grids                !< size of the collection
      INTEGER(kind=YAC_MPI_FINT_KIND), PRIVATE :: comm  !< local MPI communicator
      TYPE(yac_dist_grid_pair_f), DIMENSION(:), &
         & ALLOCATABLE, PRIVATE :: pairs !< array of distributed grid pair types
   CONTAINS
      PROCEDURE, PUBLIC :: init => dgp_init !< initialization
      PROCEDURE, PUBLIC :: get => dgp_get   !< recover index if stored or generate
      PROCEDURE, PUBLIC :: pair => dgp_pair !< give F90 access to a dist grid pair structure
      PROCEDURE, PUBLIC :: free => dgp_free !< finalization
   END TYPE dist_grid_pair_collection

   ! Static shared data

   ! MPI arguments
   INTEGER :: comm_rank, comm_size
   INTEGER(kind=YAC_MPI_FINT_KIND) :: mpi_comm_yac

   ! Storage of YAC grid structures
   TYPE(basic_grid_collection) :: basic_grid

   ! Storage of YAC distributed grid pairs structures
   TYPE(dist_grid_pair_collection) :: dist_grid_pair

   ! Timers switch
   INTEGER, PARAMETER :: local_timers_on = 0   ! 0=None, 1=overall, 2=detailed

CONTAINS

   ! Manipulation of the YAC basic_grid types

   !> Initialization of a YAC basic grid type
   !! @param [inout] self   the basic grid collection to be allocated
   !! @param [in] max_size  the maximum possible number of grids
   !! @param [in] comm      the local MPI communicator
   SUBROUTINE bg_init(self, max_size, comm)

      CLASS(basic_grid_collection), INTENT(INOUT) :: self
      INTEGER, INTENT(IN) :: max_size
      INTEGER(kind=YAC_MPI_FINT_KIND), INTENT(IN) :: comm

      ALLOCATE(self%grids(max_size))
      self%comm = comm
      self%num_basic_grids = 0

   END SUBROUTINE bg_init

   !> Finalization of a YAC basic grid type
   !! @param [inout] self   the basic grid collection to be cleared
   SUBROUTINE bg_free(self)

      CLASS(basic_grid_collection), INTENT(INOUT) :: self

      INTEGER :: i

      DO i = 1, self%num_basic_grids
         DEALLOCATE(self%grids(i)%id, &
                    self%grids(i)%grid_filename, &
                    self%grids(i)%mask_filename)
         CALL yac_basic_grid_delete_c(self%grids(i)%grid)
         CALL yac_free_c(self%grids(i)%duplicated_cell_idx)
         CALL yac_free_c(self%grids(i)%orig_cell_global_id)
      END DO
      IF (ALLOCATED(self%grids)) DEALLOCATE(self%grids)
      self%num_basic_grids = 0

   END SUBROUTINE bg_free

   !> Recover the index of a basic grid type in the collection if stored
   !! or read the grid and its mask from files and add it to the collection
   !! @param [inout] self   the basic grid collection
   !! @param [in] grid_name     the name of the grid
   !! @param [in] grid_filename the filename of the NetCDF SCRIP-like description of the grids
   !! @param [in] mask_filename the filename of the NetCDF SCRIP-like description of the masks
   !! @param [in] use_ll    toggle the lon/lat edge representation (use great circles if false)
   !! @return the index of the grid in the collection
   FUNCTION bg_get(self, grid_name, grid_filename, mask_filename, use_ll)

      USE mpi

      CLASS(basic_grid_collection), INTENT(INOUT) :: self
      CHARACTER(LEN=*), INTENT(IN) :: grid_name
      CHARACTER(LEN=*), INTENT(IN) :: grid_filename
      CHARACTER(LEN=*), INTENT(IN) :: mask_filename
      LOGICAL, INTENT(IN)          :: use_ll

      INTEGER :: bg_get

      INTEGER :: i
      INTEGER(kind=c_int) :: i_use_ll
      INTEGER(kind=c_size_t) :: coords_idx
      INTEGER :: local_grid_size(1), global_grid_size(1), ierror

      ! check whether the grid collection has already been initialized
      IF (.NOT. ALLOCATED(self%grids)) &
         CALL yac_abort_message_c( &
            'Basic grids have not yet been initialized' // c_null_char, &
            __FILE__, __LINE__)

      ! check whether the grid has already been read
      DO i = 1, self%num_basic_grids
         IF (TRIM(self%grids(i)%id) == TRIM(grid_name) .AND. &
             TRIM(self%grids(i)%grid_filename) == TRIM(grid_filename) .AND. &
             TRIM(self%grids(i)%mask_filename) == TRIM(mask_filename)) THEN
            bg_get = i
            RETURN
         END IF
      END DO

      self%num_basic_grids = self%num_basic_grids + 1
      IF (self%num_basic_grids > SIZE(self%grids)) &
         CALL yac_abort_message_c( &
            'Exceeded basic grid collection storage size' // c_null_char, &
            __FILE__, __LINE__)
      bg_get = self%num_basic_grids
      i = self%num_basic_grids
      i_use_ll = MERGE(1_c_int, 0_c_int, use_ll)

      ! read the grid data from file
      self%grids(i)%grid = &
         yac_read_scrip_basic_grid_parallel_c( &
            TRIM(grid_filename) //c_null_char, &
            TRIM(mask_filename) //c_null_char, &
            self%comm, TRIM(grid_name) //c_null_char, &
            0_c_int, TRIM(grid_name) //c_null_char, i_use_ll, coords_idx, &
            self%grids(i)%duplicated_cell_idx, &
            self%grids(i)%orig_cell_global_id, &
            self%grids(i)%nbr_duplicated_cells)

      local_grid_size(1) = &
         INT(yac_basic_grid_get_data_size_c( &
             self%grids(i)%grid, YAC_LOC_CELL))
      CALL MPI_Allreduce( &
         local_grid_size, global_grid_size, 1, MPI_INTEGER, &
         MPI_SUM, self%comm, ierror)

      self%grids(i)%id = TRIM(grid_name)
      self%grids(i)%grid_filename = TRIM(grid_filename)
      self%grids(i)%mask_filename = TRIM(mask_filename)
      self%grids(i)%grid_size = INT(global_grid_size(1), c_size_t)

   END FUNCTION bg_get

   !> Recover a basic grid name by position
   !! @param [in] self   the basic grid collection
   !! @param [in] idx    the basic grid index
   !! @return the name (identifier) of the basic grid
   PURE FUNCTION bg_id(self, idx) RESULT(id)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      CHARACTER(LEN=:), ALLOCATABLE :: id

      id = TRIM(self%grids(idx)%id) // c_null_char

   END FUNCTION bg_id

   !> Recover a basic grid size by position
   !! @param [in] self   the basic grid collection
   !! @param [in] idx    the basic grid index
   !! @return the size of the basic grid
   PURE FUNCTION bg_grid_size(self, idx) RESULT(grid_size)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      INTEGER(c_size_t) :: grid_size

      grid_size = self%grids(idx)%grid_size

   END FUNCTION bg_grid_size

   !> Give F90 access to a basic grid type
   !! @param [in] self   the basic grid collection
   !! @param [in] idx    the basic grid index
   !! @return the pointer to the YAC storage of the basic grid
   PURE FUNCTION bg_grid(self, idx) RESULT(grid)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      TYPE(c_ptr) :: grid

      grid = self%grids(idx)%grid

   END FUNCTION bg_grid

   !> Give F90 access to the array of the reference cells for duplicated entries
   !! @param [in] self   the basic grid collection
   !! @param [in] idx    the basic grid index
   !! @return the pointer to the YAC storage of the reference cells array
   PURE FUNCTION bg_orig_cell_global_id(self, idx) RESULT(orig_cell_global_id)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      TYPE(c_ptr) :: orig_cell_global_id

      orig_cell_global_id = self%grids(idx)%orig_cell_global_id

   END FUNCTION bg_orig_cell_global_id

   !> Give F90 access to the array of the duplicated cells
   !! @param [in] self   the basic grid collection
   !! @param [in] idx    the basic grid index
   !! @return the pointer to the YAC storage of the duplicated cells array
   PURE FUNCTION bg_duplicated_cell_idx(self, idx) RESULT(duplicated_cell_idx)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      TYPE(c_ptr) :: duplicated_cell_idx

      duplicated_cell_idx = self%grids(idx)%duplicated_cell_idx

   END FUNCTION bg_duplicated_cell_idx

   !> Recover the number of duplicated cells
   !! @param [in] self   the basic grid collection
   !! @param [in] idx    the basic grid index
   !! @return the number of duplicated cells
   PURE FUNCTION bg_nbr_duplicated_cells(self, idx) RESULT(nbr_duplicated_cells)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      INTEGER(c_size_t) :: nbr_duplicated_cells

      nbr_duplicated_cells = self%grids(idx)%nbr_duplicated_cells

   END FUNCTION bg_nbr_duplicated_cells

   ! Manipulation of the YAC dist_grid_pair types

   !> Initialization of a YAC distributed grid pair type
   !! @param [inout] self   the dist grid pair collection to be allocated
   !! @param [in] max_size  the maximum possible number of pairs
   !! @param [in] comm      the local MPI communicator
   SUBROUTINE dgp_init(self, max_size, comm)

      CLASS(dist_grid_pair_collection), INTENT(INOUT) :: self
      INTEGER, INTENT(IN) :: max_size
      INTEGER(kind=YAC_MPI_FINT_KIND), INTENT(IN) :: comm

      ALLOCATE(self%pairs(max_size))
      self%comm = comm
      self%num_dist_grids = 0

   END SUBROUTINE dgp_init

   !> Finalization of a YAC distributed grid pair type
   !! @param [inout] self   the dist grid pair collection to be cleared
   SUBROUTINE dgp_free(self)

      CLASS(dist_grid_pair_collection), INTENT(INOUT) :: self

      INTEGER :: i

      DO i = 1, self%num_dist_grids
         CALL yac_dist_grid_pair_delete_c(self%pairs(i)%pair)
      END DO
      IF (ALLOCATED(self%pairs)) DEALLOCATE(self%pairs)
      self%num_dist_grids = 0

   END SUBROUTINE dgp_free

   !> Recover the index of a distributed grid pair type in the collection if stored
   !! or generate it from two basic grids and add it to the collection
   !! @param [inout] self   the distributed grid pair collection to be allocated
   !! @param [in] basic_grid    the collection of the basic grids
   !! @param [in] grid_a  the index in the basic grid collection of the first grid
   !! @param [in] grid_b  the index in the basic grid collection of the second grid
   !! @return the index of the distributed grid pair in the collection
   FUNCTION dgp_get(self, basic_grid, grid_a, grid_b)

      CLASS(dist_grid_pair_collection), INTENT(INOUT) :: self
      TYPE(basic_grid_collection), INTENT(IN) :: basic_grid
      INTEGER, INTENT(IN) :: grid_a
      INTEGER, INTENT(IN) :: grid_b

      INTEGER :: dgp_get

      INTEGER :: i

      ! check whether the grid collection has already been initialized
      IF (.NOT. ALLOCATED(self%pairs)) &
         CALL yac_abort_message_c( &
            'Dist grid pairs have not yet been initialized', &
            __FILE__, __LINE__)

      DO i = 1, self%num_dist_grids
         IF (((self%pairs(i)%grids(1) == grid_a) .AND. &
              (self%pairs(i)%grids(2) == grid_b)) .OR. &
             ((self%pairs(i)%grids(2) == grid_a) .AND. &
              (self%pairs(i)%grids(1) == grid_b))) THEN
            dgp_get = i
            RETURN
         END IF
      END DO

      self%num_dist_grids = self%num_dist_grids + 1
      IF (self%num_dist_grids > SIZE(self%pairs)) &
         CALL yac_abort_message_c( &
            'Exceeded dist grid pair collection storage size', &
            __FILE__, __LINE__)
      dgp_get = self%num_dist_grids
      i = self%num_dist_grids

      ! generate distributed grid pair
      self%pairs(i)%pair = &
        yac_dist_grid_pair_new_c( &
         basic_grid%grid(grid_a), basic_grid%grid(grid_b), self%comm)
      self%pairs(i)%grids(1) = grid_a
      self%pairs(i)%grids(2) = grid_b

   END FUNCTION dgp_get

   !> Give F90 access to a distributed grid pair type
   !! @param [in] self   the dist grid pair collection
   !! @param [in] idx    the dist grid pair index
   !! @return the pointer to the YAC storage of the distributed grid pair
   PURE FUNCTION dgp_pair(self, idx) RESULT(pair)

      CLASS(dist_grid_pair_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      TYPE(c_ptr) :: pair

      pair = self%pairs(idx)%pair

   END FUNCTION dgp_pair

   ! Mapping Weights Computation
   ! ---------------------------

   !> Initialisation of the YAC communication context and allocation
   !! of the basic grids and distributed grid pairs collections
   SUBROUTINE oasis_map_yac_init()

      IMPLICIT NONE

      ! Identifier
      CHARACTER(len=*),PARAMETER :: subname = '(oasis_map_yac_init)'

      ! Error code
      INTEGER :: ierror

      CALL oasis_debug_enter(subname)
      IF ( local_timers_on >=1 ) CALL oasis_timer_start('cpl_yac_init')

      ! Initialize YAXT
      CALL yac_yaxt_init_c(mpi_comm_local)

      ! Initialize YAC MPI
      CALL mpi_comm_dup(mpi_comm_local, mpi_comm_yac, ierror)
      CALL mpi_comm_rank(mpi_comm_yac, comm_rank, ierror)
      CALL mpi_comm_size(mpi_comm_yac, comm_size, ierror)

      ! Initialize the structures for reusing YAC grid definitions (names and pointers)
      ! Allows up to 2 basic grids and 1 grid pair per coupling fields
      CALL basic_grid%init(2*nnamcpl, mpi_comm_yac)
      CALL dist_grid_pair%init(nnamcpl, mpi_comm_yac)

      IF ( local_timers_on >=1 ) CALL oasis_timer_stop('cpl_yac_init')
      CALL oasis_debug_exit(subname)

   END SUBROUTINE oasis_map_yac_init

   !> Finalisation of the YAC communication context and clean up
   !! of the basic grids and distributed grid pairs collections
   SUBROUTINE oasis_map_yac_free()

      IMPLICIT NONE

      ! Identifier
      CHARACTER(len=*),PARAMETER :: subname = '(oasis_map_yac_free)'

      ! Error code
      INTEGER :: ierror

      CALL oasis_debug_enter(subname)
      IF ( local_timers_on >=1 ) CALL oasis_timer_start('cpl_yac_free')

      CALL dist_grid_pair%free()
      CALL basic_grid%free()

      ! Finalize YAXT and MPI
      CALL mpi_comm_free(mpi_comm_yac, ierror)
      CALL yac_mpi_finalize_c()

      IF ( local_timers_on >=1 ) CALL oasis_timer_stop('cpl_yac_free')
      CALL oasis_debug_exit(subname)

   END SUBROUTINE oasis_map_yac_free

   !> Generation of the mapping (interpolation) weights and their output to a file.
   !! It includes the treatment of the duplicated cells by replication of the
   !! reference cell stecil, very much like in the TREAT_OVERLAY case for the SCRIP
   !! @param [in] mapID index of the prism_mapper for this transformation
   !! @param [in] namID index of the namcouple field for this transformation
   SUBROUTINE oasis_map_yac_genmap(mapID,namID)

      IMPLICIT NONE

      INTEGER(ip_i4_p), INTENT(IN) :: mapID
      INTEGER(ip_i4_p), INTENT(IN) :: namID
      !----------------------------------------------------------

      ! Identifier
      CHARACTER(len=*),PARAMETER :: subname = '(oasis_map_yac_genmap)'

      ! Loop counters
      INTEGER :: ib_s

      ! Error code
      INTEGER :: ierror

      ! Accessory data for YAC structures scanning
      INTEGER :: j_src, j_tgt, j_pair
      CHARACTER(LEN=*), PARAMETER :: cspval = "spval_undef"

      ! data structures generated by YAC
      TYPE(c_ptr) :: interp_grid
      TYPE(c_ptr) :: interp_stack_config
      TYPE(c_ptr) :: interp_method_stack
      TYPE(c_ptr) :: interp_weights
      INTEGER(kind=c_int) :: avg_meth
      INTEGER(kind=c_int) :: i_avg_partial
      INTEGER(kind=c_int) :: nnn_meth
      INTEGER(kind=c_int) :: spm_meth
      INTEGER(kind=c_int) :: cons_order
      INTEGER(kind=c_int) :: cons_norm

      CALL oasis_debug_enter(subname)
      IF ( local_timers_on >=1 ) CALL oasis_timer_start('cpl_yac_genmap')

      ! Tune the io settings if specified in the namcouple
      IF (TRIM(namyacmet(namID)%io_ranks_per_node) /= TRIM(cspval)) &
         & ierror = INT(setenv_c(TRIM("YAC_IO_MAX_NUM_RANKS_PER_NODE")//c_null_char, &
         &                       TRIM(namyacmet(namID)%io_ranks_per_node)//c_null_char, &
         &                       1_c_int), &
         &              KIND = KIND(ierror))

      IF (OASIS_debug >= 2) WRITE(nulprt,'(2A,I3,2A)') TRIM(subname), &
         & ' Field : ',namID, ' file: ',TRIM(prism_mapper(mapID)%file)

      ! Get basic grids
      IF ( local_timers_on >=2 ) CALL oasis_timer_start('cpl_yac_genmap_basicgrid')

      j_src = &
         basic_grid%get( &
            namsrcgrd(namID), 'grids.nc', 'masks.nc', &
            namyacmet(namID)%src_use_ll)
      j_tgt = &
         basic_grid%get( &
            namdstgrd(namID), 'grids.nc', 'masks.nc', &
            namyacmet(namID)%dst_use_ll)

      IF ( local_timers_on >=2 ) CALL oasis_timer_stop('cpl_yac_genmap_basicgrid')

      IF (OASIS_debug >= 10) THEN
         WRITE(nulprt,'(4A,I3)') TRIM(subname), &
            & ' For src grid: ', TRIM(namsrcgrd(namID)), ' got basic_grid: ',j_src
         WRITE(nulprt,'(4A,I3)') TRIM(subname), &
            & ' For dst grid: ', TRIM(namdstgrd(namID)), ' got basic_grid: ',j_tgt
      END IF

      ! Get distributed grid pair
      IF ( local_timers_on >=2 ) CALL oasis_timer_start('cpl_yac_genmap_gridpair')

      j_pair = dist_grid_pair%get(basic_grid, j_src, j_tgt)

      IF ( local_timers_on >=2 ) CALL oasis_timer_stop('cpl_yac_genmap_gridpair')

      IF (OASIS_debug >= 10) WRITE(nulprt,'(2A,I3)') TRIM(subname), &
         & ' Got grid pair: ', j_pair

      ! Generate interpolation grid
      !   The interpolation grid contains a grid pair and assigns
      !   the source and target role to them. In addition, it contains
      !   additional information about the source and target fields
      !   (which coordinates and masks register in the basic grid
      !   is to be used).
      !   (this operation is collective)
      interp_grid =                                                                  &
         yac_interp_grid_new_c(                                                      &
               & dist_grid_pair%pair(j_pair), basic_grid%id(j_src),                  &
               & basic_grid%id(j_tgt),  1_c_size_t,                                  &
               & (/INT(YAC_LOC_CELL, c_int)/), (/0_c_size_t/), (/-1_c_size_t/), &
               & INT(YAC_LOC_CELL, c_int), 0_c_size_t, -1_c_size_t)

      IF (OASIS_debug >= 10) WRITE(nulprt,'(2A)') TRIM(subname), &
         & ' Created the interpolation grid'

      ! Configure the interpolation stack
      !   The interpolation stack configuration contains the information
      !   about the interpolation methods that are to be used in the
      !   interpolation. YAC has yac_interp_stack_config_add_* routines
      !   for all supported interpolation methods. In the weight
      !   computation, YAC starts with the first entry in the stack.
      !   All target points not interpolated by it, will be passed to
      !   the next method and so on...
      !   (the configuration has to be consistent on all processes)
      interp_stack_config = yac_interp_stack_config_new_c()
      DO ib_s = 1, namyacmet(namID)%stacksize
         SELECT CASE(TRIM(namyacmet(namID)%yac_stack(ib_s)%method))
         CASE('CONSERV')
            SELECT CASE(TRIM(namyacmet(namID)%yac_stack(ib_s)%cons_order))
            CASE('FIRST')
               cons_order = 1_c_int
            CASE('SECOND')
               cons_order = 2_c_int
            END SELECT
            SELECT CASE(TRIM(namyacmet(namID)%yac_stack(ib_s)%cons_norm))
            CASE('DESTAREA')
               cons_norm = YAC_INTERP_CONSERV_DESTAREA
            CASE('FRACAREA')
               cons_norm = YAC_INTERP_CONSERV_FRACAREA
            END SELECT
            CALL yac_interp_stack_config_add_conservative_c( &
               & interp_stack_config, cons_order, 0_c_int, 1_c_int, cons_norm)
         CASE('AVG')
            SELECT CASE(TRIM(namyacmet(namID)%yac_stack(ib_s)%avg_meth))
            CASE('ARITHMETIC')
               avg_meth = YAC_INTERP_AVG_ARITHMETIC
            CASE('DIST')
               avg_meth = YAC_INTERP_AVG_DIST
            CASE('BARY')
               avg_meth = YAC_INTERP_AVG_BARY
            END SELECT
            i_avg_partial = MERGE(1_c_int, 0_c_int, namyacmet(namID)%yac_stack(ib_s)%avg_partial)
            CALL yac_interp_stack_config_add_average_c( &
               & interp_stack_config, avg_meth, i_avg_partial)
         CASE('NNN')
            SELECT CASE(TRIM(namyacmet(namID)%yac_stack(ib_s)%nnn_meth))
            CASE('AVG')
               nnn_meth = YAC_INTERP_NNN_AVG
            CASE('DIST')
               nnn_meth = YAC_INTERP_NNN_DIST
            CASE('GAUSS')
               nnn_meth = YAC_INTERP_NNN_GAUSS
            CASE('RBF')
               nnn_meth = YAC_INTERP_NNN_RBF
            END SELECT
            CALL yac_interp_stack_config_add_nnn_c( &
               & interp_stack_config, nnn_meth, &
               & INT(namyacmet(namID)%yac_stack(ib_s)%nnn_points,c_size_t), &
               & REAL(namyacmet(namID)%yac_stack(ib_s)%nnn_scale,c_double))
         CASE('CREEP')
            CALL yac_interp_stack_config_add_creep_c( &
               interp_stack_config, INT(namyacmet(namID)%yac_stack(ib_s)%creep_iter,c_int))
         CASE('HCSBB')
            CALL yac_interp_stack_config_add_hcsbb_c( &
               interp_stack_config)
         CASE('SPMAP')
            SELECT CASE(TRIM(namyacmet(namID)%yac_stack(ib_s)%spm_meth))
            CASE('AVG')
               spm_meth = YAC_INTERP_SPMAP_AVG
            CASE('DIST')
               spm_meth = YAC_INTERP_SPMAP_DIST
            END SELECT
            CALL yac_interp_stack_config_add_spmap_c( &
               & interp_stack_config, &
               & REAL(namyacmet(namID)%yac_stack(ib_s)%spm_spread,c_double), &
               & REAL(namyacmet(namID)%yac_stack(ib_s)%spm_max_radius,c_double), &
               & spm_meth)
         CASE('FILE')
            CALL yac_interp_stack_config_add_user_file_c( &
               & interp_stack_config, &
               & TRIM(namyacmet(namID)%yac_stack(ib_s)%file_name)//c_null_char, &
               & TRIM(namsrcgrd(namID))//c_null_char, TRIM(namdstgrd(namID))//c_null_char)
         END SELECT
      END DO

      ! Generate the actual interpolation stack
      interp_method_stack = &
         & yac_interp_stack_config_generate_c(interp_stack_config)

      IF (OASIS_debug >= 10) WRITE(nulprt,'(2A)') TRIM(subname), &
         & ' Created the interpolation stack'

      ! execute the interpolation stack and generate the weights
      !   YAC starts by extracting all non-masked target points, which
      !   are then passed to the interpolation stack.
      !   The resulting interpolation weights contains the interpolation
      !   stencils, which are distributed across all processes.
      !   (this operation is collective)
      IF ( local_timers_on >=2 ) CALL oasis_timer_start('cpl_yac_genmap_weights')

      interp_weights = &
         & yac_interp_method_do_search_c(interp_method_stack, interp_grid)

      ! deal with duplicated target cells
      CALL yac_duplicate_stencils_c( &
         & interp_weights, basic_grid%grid(j_tgt), &
         & basic_grid%orig_cell_global_id(j_tgt), &
         & basic_grid%duplicated_cell_idx(j_tgt), &
         & basic_grid%nbr_duplicated_cells(j_tgt), YAC_LOC_CELL)

      IF ( local_timers_on >=2 ) CALL oasis_timer_stop('cpl_yac_genmap_weights')

      IF (OASIS_debug >= 10) WRITE(nulprt,'(2A)') TRIM(subname), &
         & ' Generated the interpolation weights'

      ! write weights to file
      !   This is done in parallel by a subset of all processes.
      IF ( local_timers_on >=2 ) CALL oasis_timer_start('cpl_yac_genmap_writefile')

      CALL yac_interp_weights_write_to_file_c(             &
         & interp_weights, TRIM(ADJUSTL(prism_mapper(mapID)%file))//c_null_char, &
         & basic_grid%id(j_src),        &
         & basic_grid%id(j_tgt),        &
         & basic_grid%grid_size(j_src), &
         & basic_grid%grid_size(j_tgt))

      IF ( local_timers_on >=2 ) CALL oasis_timer_stop('cpl_yac_genmap_writefile')

      IF (OASIS_debug >= 10) WRITE(nulprt,'(2A)') TRIM(subname), &
         & ' Written the interpolation weights'

      ! Reset the io settings to default if it was specified in the namcouple
      IF (TRIM(namyacmet(namID)%io_ranks_per_node) /= TRIM(cspval)) &
         & ierror = INT(setenv_c(TRIM("YAC_IO_MAX_NUM_RANKS_PER_NODE")//c_null_char, &
         &                       TRIM("0")//c_null_char, &
         &                       1_c_int), &
         &              KIND = KIND(ierror))

      ! cleanup
      CALL yac_interp_weights_delete_c(interp_weights)
      CALL yac_interp_method_delete_c(interp_method_stack)
      CALL yac_free_c(interp_method_stack)
      CALL yac_interp_stack_config_delete_c(interp_stack_config)
      CALL yac_interp_grid_delete_c(interp_grid)
      DEALLOCATE(namyacmet(namID)%yac_stack)

      IF (OASIS_debug >= 10) WRITE(nulprt,'(2A)') TRIM(subname), &
         & ' Cleanup done'

      IF ( local_timers_on >=1 ) CALL oasis_timer_stop('cpl_yac_genmap')
      CALL oasis_debug_exit(subname)

   END SUBROUTINE oasis_map_yac_genmap

#endif

END MODULE mod_oasis_yac_map
