
!> OASIS map (interpolation) weight generation with YAC. Data and methods

MODULE mod_oasis_yac_map

   USE mod_oasis_kinds
   USE mod_oasis_data
   USE mod_oasis_namcouple
   USE mod_oasis_map, ONLY: prism_mapper
   USE mod_oasis_sys, ONLY: oasis_debug_enter, oasis_debug_exit!AP, oasis_debug_note
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

      ! Low level C functions access
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

   ! Storage of YAC grid structures
   TYPE, PRIVATE :: yac_grid_f
      CHARACTER(LEN=:), ALLOCATABLE :: id
      CHARACTER(LEN=:), ALLOCATABLE :: grid_filename
      CHARACTER(LEN=:), ALLOCATABLE :: mask_filename
      TYPE(c_ptr) :: grid
      TYPE(c_ptr) :: duplicated_cell_idx
      TYPE(c_ptr) :: orig_cell_global_id
      INTEGER(c_size_t) :: nbr_duplicated_cells
      INTEGER(c_size_t) :: grid_size
   END TYPE yac_grid_f

   ! Storage of YAC distributed grid pairs structures
   TYPE, PRIVATE ::  yac_dist_grid_pair_f
      TYPE(c_ptr) :: pair
      INTEGER :: grids(2)
   END TYPE yac_dist_grid_pair_f

   ! Accessible encapsulated collections
   TYPE basic_grid_collection
      INTEGER, PRIVATE :: num_basic_grids
      INTEGER(kind=YAC_MPI_FINT_KIND), PRIVATE :: comm
      TYPE(yac_grid_f), DIMENSION(:), ALLOCATABLE, PRIVATE :: grids
   CONTAINS
      PROCEDURE, PUBLIC :: init => bg_init
      PROCEDURE, PUBLIC :: get => bg_get
      PROCEDURE, PUBLIC :: id => bg_id
      PROCEDURE, PUBLIC :: grid_size => bg_grid_size
      PROCEDURE, PUBLIC :: grid => bg_grid
      PROCEDURE, PUBLIC :: orig_cell_global_id => bg_orig_cell_global_id
      PROCEDURE, PUBLIC :: duplicated_cell_idx => bg_duplicated_cell_idx
      PROCEDURE, PUBLIC :: nbr_duplicated_cells => bg_nbr_duplicated_cells
      PROCEDURE, PUBLIC :: free => bg_free
   END TYPE basic_grid_collection

   TYPE dist_grid_pair_collection
      INTEGER, PRIVATE :: num_dist_grids
      INTEGER(kind=YAC_MPI_FINT_KIND), PRIVATE :: comm
      TYPE(yac_dist_grid_pair_f), DIMENSION(:), ALLOCATABLE, PRIVATE :: pairs
   CONTAINS
      PROCEDURE, PUBLIC :: init => dgp_init
      PROCEDURE, PUBLIC :: get => dgp_get
      PROCEDURE, PUBLIC :: pair => dgp_pair
      PROCEDURE, PUBLIC :: free => dgp_free
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
   INTEGER, PARAMETER :: local_timers_on = 2   ! 0=None, 1=overall, 2=detailed

CONTAINS

   ! Manipulation of the YAC basic_grid types

   SUBROUTINE bg_init(self, max_size, comm)

      CLASS(basic_grid_collection), INTENT(INOUT) :: self
      INTEGER, INTENT(IN) :: max_size
      INTEGER(kind=YAC_MPI_FINT_KIND), INTENT(IN) :: comm

      ALLOCATE(self%grids(max_size))
      self%comm = comm
      self%num_basic_grids = 0

   END SUBROUTINE bg_init

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

   PURE FUNCTION bg_id(self, idx) RESULT(id)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      CHARACTER(LEN=:), ALLOCATABLE :: id

      id = TRIM(self%grids(idx)%id) // c_null_char

   END FUNCTION bg_id

   PURE FUNCTION bg_grid_size(self, idx) RESULT(grid_size)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      INTEGER(c_size_t) :: grid_size

      grid_size = self%grids(idx)%grid_size

   END FUNCTION bg_grid_size

   PURE FUNCTION bg_grid(self, idx) RESULT(grid)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      TYPE(c_ptr) :: grid

      grid = self%grids(idx)%grid

   END FUNCTION bg_grid

   PURE FUNCTION bg_orig_cell_global_id(self, idx) RESULT(orig_cell_global_id)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      TYPE(c_ptr) :: orig_cell_global_id

      orig_cell_global_id = self%grids(idx)%orig_cell_global_id

   END FUNCTION bg_orig_cell_global_id

   PURE FUNCTION bg_duplicated_cell_idx(self, idx) RESULT(duplicated_cell_idx)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      TYPE(c_ptr) :: duplicated_cell_idx

      duplicated_cell_idx = self%grids(idx)%duplicated_cell_idx

   END FUNCTION bg_duplicated_cell_idx

   PURE FUNCTION bg_nbr_duplicated_cells(self, idx) RESULT(nbr_duplicated_cells)

      CLASS(basic_grid_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      INTEGER(c_size_t) :: nbr_duplicated_cells

      nbr_duplicated_cells = self%grids(idx)%nbr_duplicated_cells

   END FUNCTION bg_nbr_duplicated_cells

   ! Manipulation of the YAC dist_grid_pair types

   SUBROUTINE dgp_init(self, max_size, comm)

      CLASS(dist_grid_pair_collection), INTENT(INOUT) :: self
      INTEGER, INTENT(IN) :: max_size
      INTEGER(kind=YAC_MPI_FINT_KIND), INTENT(IN) :: comm

      ALLOCATE(self%pairs(max_size))
      self%comm = comm
      self%num_dist_grids = 0

   END SUBROUTINE dgp_init

   SUBROUTINE dgp_free(self)

      CLASS(dist_grid_pair_collection), INTENT(INOUT) :: self

      INTEGER :: i

      DO i = 1, self%num_dist_grids
         CALL yac_dist_grid_pair_delete_c(self%pairs(i)%pair)
      END DO
      IF (ALLOCATED(self%pairs)) DEALLOCATE(self%pairs)
      self%num_dist_grids = 0

   END SUBROUTINE dgp_free

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

   PURE FUNCTION dgp_pair(self, idx) RESULT(pair)

      CLASS(dist_grid_pair_collection), INTENT(IN) :: self
      INTEGER, INTENT(IN) :: idx

      TYPE(c_ptr) :: pair

      pair = self%pairs(idx)%pair

   END FUNCTION dgp_pair

   ! Mapping Weights Computation
   ! ---------------------------

   ! Initialisation

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

   ! Finalisation

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

   ! The Mapper

   SUBROUTINE oasis_map_yac_genmap(mapID,namID)

      IMPLICIT NONE

      INTEGER(ip_i4_p), INTENT(in) :: mapID  !< map id
      INTEGER(ip_i4_p), INTENT(in) :: namID  !< namcouple id
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
