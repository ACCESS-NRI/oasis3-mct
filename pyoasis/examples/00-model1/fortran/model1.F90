!------------------------------------------------------------------------
! Copyright 2010, CERFACS, Toulouse, France.
! All rights reserved. Use is subject to OASIS3 license terms.
!=============================================================================
!
PROGRAM model1
  !
  use mod_oasis

  IMPLICIT NONE
  INCLUDE 'mpif.h'
  integer :: compid, ierror, local_comm, coupl_comm, kinfo
  integer :: var_type, part_id
  integer :: var_id(2), var_nodims(2), var_sh(2)
  character(len=6) :: compname = "model1"
  character(len=8) :: var_name1 = "FSENDOCN"

  call MPI_Init(ierror)
  if (ierror<0) then
    print *, "Error initialising MPI (error: ", ierror, ")"
    return
  end if

  print *, "Component name: ", compname

  call oasis_init_comp(compid, compname, ierror)
  if(ierror<0) then
    print *, "Error initialising component (error: ", ierror, ")"
    return  
  end if
  print *, "Component id: ",compid

  CALL oasis_get_localcomm(local_comm, ierror)
  if(ierror<0) then
     print *, "Error initialising local communicator (error: ", ierror, ")"
     return
  end if
  print *, "Local communicator: ", local_comm

  CALL oasis_create_couplcomm(1, local_comm, coupl_comm, ierror)
  if(ierror<0) then
    print *, "Error initialising coupling communicator (error: ", ierror, ")"
    return 
  end if
  print *, "Coupling communicator: ", coupl_comm
  
  CALL oasis_enddef(ierror)
  if(ierror<0) then
    print *, "Error in ending definition (error: ", ierror, ")"
    return  
  end if

  CALL oasis_terminate(ierror)
  if(ierror<0) then
    print *, "Error in terminating (error: ", ierror, ")"
    return
  end if

  CALL MPI_Finalize(ierror)
  if(ierror<0) then
    print *, "Error in finalizing MPI (error: ", ierror, ")"
 end if
 
END PROGRAM MODEL1
