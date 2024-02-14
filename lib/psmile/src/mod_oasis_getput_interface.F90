
!> OASIS send/receive (put/get) user interfaces

MODULE mod_oasis_getput_interface
!---------------------------------------------------------------------

    use mod_oasis_kinds
    use mod_oasis_data
    use mod_oasis_parameters
    use mod_oasis_advance
    use mod_oasis_var
    use mod_oasis_sys

    implicit none
    private

    public oasis_put
    public oasis_get

#include "oasis_os.h"

    integer(kind=ip_i4_p)     istatus(MPI_STATUS_SIZE)

!> Generic overloaded interface for data put (send)
  interface oasis_put
#ifndef __NO_4BYTE_REALS
     module procedure oasis_put_r14
     module procedure oasis_put_r24f1
     module procedure oasis_put_r24f2
     module procedure oasis_put_r34f2
     module procedure oasis_put_r34f3
#endif
     module procedure oasis_put_r18
     module procedure oasis_put_r28f1
     module procedure oasis_put_r28f2
     module procedure oasis_put_r38f2
     module procedure oasis_put_r38f3
  end interface

!> Generic overloaded interface for data get (receive)
  interface oasis_get
#ifndef __NO_4BYTE_REALS
     module procedure oasis_get_r14
     module procedure oasis_get_r24
     module procedure oasis_get_r34
#endif
     module procedure oasis_get_r18
     module procedure oasis_get_r28
     module procedure oasis_get_r38
  end interface

!---------------------------------------------------------------------
contains
!---------------------------------------------------------------------
#ifndef __NO_4BYTE_REALS

!> Send 4 byte real 1D data

  SUBROUTINE oasis_put_r14(var_id,kstep,fld1,kinfo, &
    fld2, fld3, fld4, fld5, write_restart, fracwgt)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_single_p)             :: fld1(:)     !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    real(kind=ip_single_p), optional :: fld2(:)       !< higher order field data
    real(kind=ip_single_p), optional :: fld3(:)       !< higher order field data
    real(kind=ip_single_p), optional :: fld4(:)       !< higher order field data
    real(kind=ip_single_p), optional :: fld5(:)       !< higher order field data
    logical               , optional :: write_restart !< write restart now
    real(kind=ip_single_p), optional :: fracwgt(:)    !< dynamic fraction weight
    !-------------------------------------
    integer(kind=ip_i4_p) :: ns
    character(len=*),parameter :: subname = '(oasis_put_r14)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    if (prism_var(var_id)%num > 1) then
       write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
       write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
       call oasis_abort(file=__FILE__,line=__LINE__)
    endif

    ! check consistency of fld sizes
    if (present(fld2)) then
       if (size(fld2) /= size(fld1)) then
          write(nulprt,*) subname,estr,'fld2 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld3)) then
       if (size(fld3) /= size(fld1)) then
          write(nulprt,*) subname,estr,'fld3 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld4)) then
       if (size(fld4) /= size(fld1)) then
          write(nulprt,*) subname,estr,'fld4 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld5)) then
       if (size(fld5) /= size(fld1)) then
          write(nulprt,*) subname,estr,'fld5 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fracwgt)) then
       if (size(fracwgt) /= size(fld1)) then
          write(nulprt,*) subname,estr,'fracwgt size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if

    ns = size(fld1)
    if (present(fracwgt)) then
       if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
               dble(fld2), dble(fld3), dble(fld4), dble(fld5),        &
               write_restart=write_restart, fracwgt=dble(fracwgt))
       elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
               dble(fld2), dble(fld3), dble(fld4),                    &
               write_restart=write_restart, fracwgt=dble(fracwgt))
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
               dble(fld2), dble(fld3),                                &
               write_restart=write_restart, fracwgt=dble(fracwgt))
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
               dble(fld2),                                            &
               write_restart=write_restart, fracwgt=dble(fracwgt))
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
          call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
               write_restart=write_restart, fracwgt=dble(fracwgt))
       else
          write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif
    else
       if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
               dble(fld2), dble(fld3), dble(fld4), dble(fld5),        &
               write_restart=write_restart)
       elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
               dble(fld2), dble(fld3), dble(fld4),                    &
               write_restart=write_restart)
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
               dble(fld2), dble(fld3),                                &
               write_restart=write_restart)
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
               dble(fld2),                                            &
               write_restart=write_restart)
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
          call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
               write_restart=write_restart)
       else
          write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif
    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_put_r14
#endif

!-------------------------------------------------------------------

!> Send 8 byte real 1D data

  SUBROUTINE oasis_put_r18(var_id,kstep,fld1,kinfo, &
    fld2, fld3, fld4, fld5, write_restart, fracwgt)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_double_p)             :: fld1(:)     !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    real(kind=ip_double_p), optional :: fld2(:)       !< higher order field data
    real(kind=ip_double_p), optional :: fld3(:)       !< higher order field data
    real(kind=ip_double_p), optional :: fld4(:)       !< higher order field data
    real(kind=ip_double_p), optional :: fld5(:)       !< higher order field data
    logical               , optional :: write_restart !< write restart now
    real(kind=ip_double_p), optional :: fracwgt(:)    !< dynamic fraction weight
    !-------------------------------------
    integer(kind=ip_i4_p) :: ns
    character(len=*),parameter :: subname = '(oasis_put_r18)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    if (prism_var(var_id)%num > 1) then
       write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
       write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
       call oasis_abort(file=__FILE__,line=__LINE__)
    endif

    ! check consistency of fld sizes
    if (present(fld2)) then
       if (size(fld2) /= size(fld1)) then
          write(nulprt,*) subname,estr,'fld2 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld3)) then
       if (size(fld3) /= size(fld1)) then
          write(nulprt,*) subname,estr,'fld3 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld4)) then
       if (size(fld4) /= size(fld1)) then
          write(nulprt,*) subname,estr,'fld4 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld5)) then
       if (size(fld5) /= size(fld1)) then
          write(nulprt,*) subname,estr,'fld5 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fracwgt)) then
       if (size(fracwgt) /= size(fld1)) then
          write(nulprt,*) subname,estr,'fracwgt size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if

    ns = size(fld1)
    if (present(fracwgt)) then
       if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
               fld2, fld3, fld4, fld5,                          &
               write_restart=write_restart, fracwgt=fracwgt)
       elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
               fld2, fld3, fld4,                                &
               write_restart=write_restart, fracwgt=fracwgt)
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
               fld2, fld3,                                      &
               write_restart=write_restart, fracwgt=fracwgt)
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
               fld2,                                            &
               write_restart=write_restart, fracwgt=fracwgt)
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
          call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
               write_restart=write_restart, fracwgt=fracwgt)
       else
          write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif
    else
       if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
               fld2, fld3, fld4, fld5,                          &
               write_restart=write_restart)
       elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
               fld2, fld3, fld4,                                &
               write_restart=write_restart)
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
               fld2, fld3,                                      &
               write_restart=write_restart)
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
          call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
               fld2,                                            &
               write_restart=write_restart)
       elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
          call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
               write_restart=write_restart)
       else
          write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif
    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_put_r18

!---------------------------------------------------------------------
#ifndef __NO_4BYTE_REALS

!> Send 4 byte real 2D data

  SUBROUTINE oasis_put_r24f1(var_id,kstep,fld1,kinfo, &
    fld2, fld3, fld4, fld5, write_restart, fracwgt)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_single_p) :: fld1(:,:)               !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    real(kind=ip_single_p), optional :: fld2(:,:)     !< higher order field data
    real(kind=ip_single_p), optional :: fld3(:,:)     !< higher order field data
    real(kind=ip_single_p), optional :: fld4(:,:)     !< higher order field data
    real(kind=ip_single_p), optional :: fld5(:,:)     !< higher order field data
    logical               , optional :: write_restart !< write restart now
    real(kind=ip_single_p), optional :: fracwgt(:)    !< dynamic fraction weight
    !-------------------------------------
    integer(kind=ip_i4_p) :: n, ns, fldszd1,fldszd2
    character(len=*),parameter :: subname = '(oasis_put_r24f1)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    ! check consistency of fld sizes
    fldszd1 = size(fld1,dim=1)
    fldszd2 = size(fld1,dim=2)
    if (present(fld2)) then
       if (size(fld2,dim=1) /= fldszd1 .or. size(fld2,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld2 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld3)) then
       if (size(fld3,dim=1) /= fldszd1 .or. size(fld3,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld3 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld4)) then
       if (size(fld4,dim=1) /= fldszd1 .or. size(fld4,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld4 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld5)) then
       if (size(fld5,dim=1) /= fldszd1 .or. size(fld5,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld5 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fracwgt)) then
       if (size(fracwgt) /= fldszd1) then
          write(nulprt,*) subname,estr,'fracwgt size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if

    if (prism_var(var_id)%num > 1) then
    ! treat data as 1d bundled data

       if (size(fld1,dim=2) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 2nd dim size = ',size(fld1,dim=2)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

       ns = size(fld1,dim=1)
       if (present(fracwgt)) then

          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)), dble(fld3(:,n)), dble(fld4(:,n)), dble(fld5(:,n)), &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:)))
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)), dble(fld3(:,n)), dble(fld4(:,n)),          &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)), dble(fld3(:,n)),                           &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)),                                            &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:)))
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
             endif
          enddo

       else

          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)), dble(fld3(:,n)), dble(fld4(:,n)), dble(fld5(:,n)), &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)), dble(fld3(:,n)), dble(fld4(:,n)),          &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)), dble(fld3(:,n)),                           &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)), dble(fld3(:,n)), dble(fld4(:,n)),          &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     write_restart=write_restart, varnum=n)
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
             endif
          enddo

       endif

    else
    ! treat data as 2d unbundled data

       ns = size(fld1)
       if (present(fracwgt)) then
          write(nulprt,*) subname,estr,' fracwgt shape incorrect in oasis_put, sending 2d data, 1d fracwgt'
          call oasis_abort(file=__FILE__,line=__LINE__)
       else
          if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3), dble(fld4), dble(fld5),        &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3), dble(fld4),                    &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3),                                &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2),                                            &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  write_restart=write_restart)
          else
             write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
             call oasis_abort(file=__FILE__,line=__LINE__)
          endif
       endif

    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_put_r24f1
#endif

!---------------------------------------------------------------------
#ifndef __NO_4BYTE_REALS

!> Send 4 byte real 2D data, complements r24f1, used only when fracwgt is passed as 2D array

  SUBROUTINE oasis_put_r24f2(var_id,kstep,fld1,kinfo, &
    fld2, fld3, fld4, fld5, write_restart, fracwgt)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_single_p) :: fld1(:,:)               !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    real(kind=ip_single_p), optional :: fld2(:,:)     !< higher order field data
    real(kind=ip_single_p), optional :: fld3(:,:)     !< higher order field data
    real(kind=ip_single_p), optional :: fld4(:,:)     !< higher order field data
    real(kind=ip_single_p), optional :: fld5(:,:)     !< higher order field data
    logical               , optional :: write_restart !< write restart now
    real(kind=ip_single_p)           :: fracwgt(:,:)  !< dynamic fraction weight
    !-------------------------------------
    integer(kind=ip_i4_p) :: n, ns, fldszd1, fldszd2
    character(len=*),parameter :: subname = '(oasis_put_r24f2)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    ! check consistency of fld sizes
    fldszd1 = size(fld1,dim=1)
    fldszd2 = size(fld1,dim=2)
    if (present(fld2)) then
       if (size(fld2,dim=1) /= fldszd1 .or. size(fld2,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld2 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld3)) then
       if (size(fld3,dim=1) /= fldszd1 .or. size(fld3,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld3 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld4)) then
       if (size(fld4,dim=1) /= fldszd1 .or. size(fld4,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld4 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld5)) then
       if (size(fld5,dim=1) /= fldszd1 .or. size(fld5,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld5 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
!    if (present(fracwgt)) then
       if (size(fracwgt,dim=1) /= fldszd1 .or. size(fracwgt,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fracwgt size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
!    end if

    if (prism_var(var_id)%num > 1) then
    ! treat data as 1d bundled data, fracwgt is same shape

       if (size(fld1,dim=2) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 2nd dim size = ',size(fld1,dim=2)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

!       if (present(fracwgt)) then
          ns = size(fld1,dim=1)
          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)), dble(fld3(:,n)), dble(fld4(:,n)), dble(fld5(:,n)), &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,n)))
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)), dble(fld3(:,n)), dble(fld4(:,n)),          &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,n)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)), dble(fld3(:,n)),                           &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,n)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     dble(fld2(:,n)), dble(fld3(:,n)), dble(fld4(:,n)),          &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,n)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,n)), ns, kinfo, &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,n)))
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
             endif
          enddo
!       endif

    else
    ! treat data as 2d unbundled data, fracwgt is same shape

!       if (present(fracwgt)) then
          ns = size(fld1)
          if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3), dble(fld4), dble(fld5),        &
                  write_restart=write_restart,fracwgt=dble(fracwgt))
          elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3), dble(fld4),                    &
                  write_restart=write_restart,fracwgt=dble(fracwgt))
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3),                                &
                  write_restart=write_restart,fracwgt=dble(fracwgt))
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2),                                            &
                  write_restart=write_restart,fracwgt=dble(fracwgt))
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  write_restart=write_restart,fracwgt=dble(fracwgt))
          else
             write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
             call oasis_abort(file=__FILE__,line=__LINE__)
          endif
!       endif

    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_put_r24f2
#endif

!---------------------------------------------------------------------
#ifndef __NO_4BYTE_REALS

!> Send 4 byte real 2D bundled data or 3D data

  SUBROUTINE oasis_put_r34f2(var_id,kstep,fld1,kinfo, &
    fld2, fld3, fld4, fld5, write_restart, fracwgt)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_single_p) :: fld1(:,:,:)             !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    real(kind=ip_single_p), optional :: fld2(:,:,:)   !< higher order field data
    real(kind=ip_single_p), optional :: fld3(:,:,:)   !< higher order field data
    real(kind=ip_single_p), optional :: fld4(:,:,:)   !< higher order field data
    real(kind=ip_single_p), optional :: fld5(:,:,:)   !< higher order field data
    logical               , optional :: write_restart !< write restart now
    real(kind=ip_single_p), optional :: fracwgt(:,:)  !< dynamic fraction weight
    !-------------------------------------
    integer(kind=ip_i4_p) :: n, ns, fldszd1, fldszd2, fldszd3
    character(len=*),parameter :: subname = '(oasis_put_r34f2)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    ! check consistency of fld sizes
    fldszd1 = size(fld1,dim=1)
    fldszd2 = size(fld1,dim=2)
    fldszd3 = size(fld1,dim=3)
    if (present(fld2)) then
       if (size(fld2,dim=1) /= fldszd1 .or. size(fld2,dim=2) /= fldszd2 .or. size(fld2,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld2 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld3)) then
       if (size(fld3,dim=1) /= fldszd1 .or. size(fld3,dim=2) /= fldszd2 .or. size(fld3,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld3 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld4)) then
       if (size(fld4,dim=1) /= fldszd1 .or. size(fld4,dim=2) /= fldszd2 .or. size(fld4,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld4 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld5)) then
       if (size(fld5,dim=1) /= fldszd1 .or. size(fld5,dim=2) /= fldszd2 .or. size(fld5,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld5 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fracwgt)) then
       if (size(fracwgt,dim=1) /= fldszd1 .or. size(fracwgt,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fracwgt size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if

    if (prism_var(var_id)%num > 1) then
    ! treat data as 2d bundled data

       if (size(fld1,dim=3) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 3rd dim size = ',size(fld1,dim=3)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

       ns = size(fld1,dim=1)*size(fld1,dim=2)
       if (present(fracwgt)) then

          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)), dble(fld3(:,:,n)), dble(fld4(:,:,n)), dble(fld5(:,:,n)),   &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,:)))
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)), dble(fld3(:,:,n)), dble(fld4(:,:,n)),      &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,:)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)), dble(fld3(:,:,n)),                         &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,:)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)),                                            &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,:)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,:)))
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
             endif
          enddo

       else

          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)), dble(fld3(:,:,n)), dble(fld4(:,:,n)), dble(fld5(:,:,n)),   &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)), dble(fld3(:,:,n)), dble(fld4(:,:,n)),      &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)), dble(fld3(:,:,n)),                         &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)),                                            &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     write_restart=write_restart, varnum=n)
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
             endif
          enddo

       endif

    else
    ! treat as 3d unbundled data
       if (present(fracwgt)) then
          write(nulprt,*) subname,estr,' fracwgt shape incorrect in oasis_put'
          call oasis_abort(file=__FILE__,line=__LINE__)
       else

          ns = size(fld1)
          if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3), dble(fld4), dble(fld5),        &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3), dble(fld4),                    &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3),                                &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2),                                            &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  write_restart=write_restart)
          else
             write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
             call oasis_abort(file=__FILE__,line=__LINE__)
          endif

       endif

    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_put_r34f2
#endif

!---------------------------------------------------------------------
#ifndef __NO_4BYTE_REALS

!> Send 4 byte real 2D bundled data with only with 2D bundled fracwgt
!> or 3D data

  SUBROUTINE oasis_put_r34f3(var_id,kstep,fld1,kinfo, &
    fld2, fld3, fld4, fld5, write_restart, fracwgt)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_single_p) :: fld1(:,:,:)             !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    real(kind=ip_single_p), optional :: fld2(:,:,:)   !< higher order field data
    real(kind=ip_single_p), optional :: fld3(:,:,:)   !< higher order field data
    real(kind=ip_single_p), optional :: fld4(:,:,:)   !< higher order field data
    real(kind=ip_single_p), optional :: fld5(:,:,:)   !< higher order field data
    logical               , optional :: write_restart !< write restart now
    real(kind=ip_single_p)           :: fracwgt(:,:,:)!< dynamic fraction weight
    !-------------------------------------
    integer(kind=ip_i4_p) :: n, ns, fldszd1, fldszd2, fldszd3
    character(len=*),parameter :: subname = '(oasis_put_r34f3)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    ! check consistency of fld sizes
    fldszd1 = size(fld1,dim=1)
    fldszd2 = size(fld1,dim=2)
    fldszd3 = size(fld1,dim=3)
    if (present(fld2)) then
       if (size(fld2,dim=1) /= fldszd1 .or. size(fld2,dim=2) /= fldszd2 .or. size(fld2,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld2 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld3)) then
       if (size(fld3,dim=1) /= fldszd1 .or. size(fld3,dim=2) /= fldszd2 .or. size(fld3,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld3 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld4)) then
       if (size(fld4,dim=1) /= fldszd1 .or. size(fld4,dim=2) /= fldszd2 .or. size(fld4,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld4 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld5)) then
       if (size(fld5,dim=1) /= fldszd1 .or. size(fld5,dim=2) /= fldszd2 .or. size(fld5,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld5 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
!    if (present(fracwgt)) then
       if (size(fracwgt,dim=1) /= fldszd1 .or. size(fracwgt,dim=2) /= fldszd2 .or. size(fracwgt,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fracwgt size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
!    end if

    if (prism_var(var_id)%num > 1) then
    ! treat data as 2d bundled data

       if (size(fld1,dim=3) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 3rd dim size = ',size(fld1,dim=3)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

!       if (present(fracwgt)) then
          ns = size(fld1,dim=1)*size(fld1,dim=2)
          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)), dble(fld3(:,:,n)), dble(fld4(:,:,n)), dble(fld5(:,:,n)),   &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,:,n)))
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)), dble(fld3(:,:,n)), dble(fld4(:,:,n)),      &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,:,n)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)), dble(fld3(:,:,n)),                         &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,:,n)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     dble(fld2(:,:,n)),                                            &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,:,n)))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, dble(fld1(:,:,n)), ns, kinfo, &
                     write_restart=write_restart, varnum=n, fracwgt=dble(fracwgt(:,:,n)))
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
             endif
          enddo
!       endif

    else
    ! treat data as 3d unbundled data
!       if (present(fracwgt)) then
          ns = size(fld1)
          if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3), dble(fld4), dble(fld5),        &
                  write_restart=write_restart,fracwgt=dble(fracwgt))
          elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3), dble(fld4),                    &
                  write_restart=write_restart,fracwgt=dble(fracwgt))
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2), dble(fld3),                                &
                  write_restart=write_restart,fracwgt=dble(fracwgt))
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  dble(fld2),                                            &
                  write_restart=write_restart,fracwgt=dble(fracwgt))
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
             call oasis_put_worker(var_id, kstep, dble(fld1), ns, kinfo, &
                  write_restart=write_restart,fracwgt=dble(fracwgt))
          else
             write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
             call oasis_abort(file=__FILE__,line=__LINE__)
          endif
!       endif
    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_put_r34f3
#endif

!---------------------------------------------------------------------

!> Send 8 byte real 2D data

  SUBROUTINE oasis_put_r28f1(var_id,kstep,fld1,kinfo, &
    fld2, fld3, fld4, fld5, write_restart, fracwgt)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_double_p) :: fld1(:,:)               !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    real(kind=ip_double_p), optional :: fld2(:,:)     !< higher order field data
    real(kind=ip_double_p), optional :: fld3(:,:)     !< higher order field data
    real(kind=ip_double_p), optional :: fld4(:,:)     !< higher order field data
    real(kind=ip_double_p), optional :: fld5(:,:)     !< higher order field data
    logical               , optional :: write_restart !< write restart now
    real(kind=ip_double_p), optional :: fracwgt(:)    !< dynamic fraction weight
    !-------------------------------------
    integer(kind=ip_i4_p) :: n, ns, fldszd1, fldszd2
    character(len=*),parameter :: subname = '(oasis_put_r28f1)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    ! check consistency of fld sizes
    fldszd1 = size(fld1,dim=1)
    fldszd2 = size(fld1,dim=2)
    if (present(fld2)) then
       if (size(fld2,dim=1) /= fldszd1 .or. size(fld2,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld2 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld3)) then
       if (size(fld3,dim=1) /= fldszd1 .or. size(fld3,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld3 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld4)) then
       if (size(fld4,dim=1) /= fldszd1 .or. size(fld4,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld4 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld5)) then
       if (size(fld5,dim=1) /= fldszd1 .or. size(fld5,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld5 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fracwgt)) then
       if (size(fracwgt) /= fldszd1) then
          write(nulprt,*) subname,estr,'fracwgt size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if

    if (prism_var(var_id)%num > 1) then
    ! treat data as 1d bundled data

       if (size(fld1,dim=2) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 2nd dim size = ',size(fld1,dim=2)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

       ns = size(fld1,dim=1)
       if (present(fracwgt)) then

          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n), fld3(:,n), fld4(:,n), fld5(:,n),           &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:))
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n), fld3(:,n), fld4(:,n),                      &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n), fld3(:,n),                                 &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n),                                            &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:))
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
              endif
          enddo

       else

          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n), fld3(:,n), fld4(:,n), fld5(:,n),           &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n), fld3(:,n), fld4(:,n),                      &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n), fld3(:,n),                                 &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n),                                            &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     write_restart=write_restart, varnum=n)
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
              endif
          enddo

       endif
    else
    ! treat data as 2d unbundled data

       ns = size(fld1)
       if (present(fracwgt)) then
          write(nulprt,*) subname,estr,' fracwgt shape incorrect in oasis_put'
          call oasis_abort(file=__FILE__,line=__LINE__)
       else
          if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3, fld4, fld5,                          &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3, fld4,                                &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3,                                      &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2,                                            &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  write_restart=write_restart)
          else
             write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
             call oasis_abort(file=__FILE__,line=__LINE__)
          endif
       endif

    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_put_r28f1

!---------------------------------------------------------------------

!> Send 8 byte real 2D data, complements r28f1, used when fracwgt is 2D passed array

  SUBROUTINE oasis_put_r28f2(var_id,kstep,fld1,kinfo, &
    fld2, fld3, fld4, fld5, write_restart, fracwgt)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_double_p) :: fld1(:,:)               !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    real(kind=ip_double_p), optional :: fld2(:,:)     !< higher order field data
    real(kind=ip_double_p), optional :: fld3(:,:)     !< higher order field data
    real(kind=ip_double_p), optional :: fld4(:,:)     !< higher order field data
    real(kind=ip_double_p), optional :: fld5(:,:)     !< higher order field data
    logical               , optional :: write_restart !< write restart now
    real(kind=ip_double_p)           :: fracwgt(:,:)  !< dynamic fraction weight
    !-------------------------------------
    integer(kind=ip_i4_p) :: n, ns, fldszd1, fldszd2
    character(len=*),parameter :: subname = '(oasis_put_r28f2)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    ! check consistency of fld sizes
    fldszd1 = size(fld1,dim=1)
    fldszd2 = size(fld1,dim=2)
    if (present(fld2)) then
       if (size(fld2,dim=1) /= fldszd1 .or. size(fld2,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld2 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld3)) then
       if (size(fld3,dim=1) /= fldszd1 .or. size(fld3,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld3 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld4)) then
       if (size(fld4,dim=1) /= fldszd1 .or. size(fld4,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld4 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld5)) then
       if (size(fld5,dim=1) /= fldszd1 .or. size(fld5,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fld5 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
!    if (present(fracwgt)) then
       if (size(fracwgt,dim=1) /= fldszd1 .or. size(fracwgt,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fracwgt size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
!    end if

    if (prism_var(var_id)%num > 1) then
    ! treat data as 1d bundled data, fracwgt is same shape

       if (size(fld1,dim=2) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 2nd dim size = ',size(fld1,dim=2)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

!       if (present(fracwgt)) then
          ns = size(fld1,dim=1)
          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n), fld3(:,n), fld4(:,n), fld5(:,n),           &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,n))
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n), fld3(:,n), fld4(:,n),                      &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,n))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n), fld3(:,n),                                 &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,n))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     fld2(:,n), fld3(:,n), fld4(:,n),                      &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,n))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,n), ns, kinfo, &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,n))
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
             endif
          enddo
!       endif

    else
    ! treat data as 2d unbundled data, fracwgt is same shape

!       if (present(fracwgt)) then
          ns = size(fld1)
          if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3, fld4, fld5,                          &
                  write_restart=write_restart,fracwgt=fracwgt)
          elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3, fld4,                                &
                  write_restart=write_restart,fracwgt=fracwgt)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3,                                      &
                  write_restart=write_restart,fracwgt=fracwgt)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2,                                            &
                  write_restart=write_restart,fracwgt=fracwgt)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  write_restart=write_restart,fracwgt=fracwgt)
          else
             write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
             call oasis_abort(file=__FILE__,line=__LINE__)
          endif
!       endif

    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_put_r28f2

!---------------------------------------------------------------------

!> Send 8 byte real 2D bundled data or 3D data without fracwgt

  SUBROUTINE oasis_put_r38f2(var_id,kstep,fld1,kinfo, &
    fld2, fld3, fld4, fld5, write_restart, fracwgt)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_double_p) :: fld1(:,:,:)             !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    real(kind=ip_double_p), optional :: fld2(:,:,:)   !< higher order field data
    real(kind=ip_double_p), optional :: fld3(:,:,:)   !< higher order field data
    real(kind=ip_double_p), optional :: fld4(:,:,:)   !< higher order field data
    real(kind=ip_double_p), optional :: fld5(:,:,:)   !< higher order field data
    logical               , optional :: write_restart !< write restart now
    real(kind=ip_double_p), optional :: fracwgt(:,:)  !< dynamic fraction weight
    !-------------------------------------
    integer(kind=ip_i4_p) :: n, ns, fldszd1, fldszd2, fldszd3
    character(len=*),parameter :: subname = '(oasis_put_r38f2)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    ! check consistency of fld sizes
    fldszd1 = size(fld1,dim=1)
    fldszd2 = size(fld1,dim=2)
    fldszd3 = size(fld1,dim=3)
    if (present(fld2)) then
       if (size(fld2,dim=1) /= fldszd1 .or. size(fld2,dim=2) /= fldszd2 .or. size(fld2,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld2 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld3)) then
       if (size(fld3,dim=1) /= fldszd1 .or. size(fld3,dim=2) /= fldszd2 .or. size(fld3,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld3 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld4)) then
       if (size(fld4,dim=1) /= fldszd1 .or. size(fld4,dim=2) /= fldszd2 .or. size(fld4,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld4 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld5)) then
       if (size(fld5,dim=1) /= fldszd1 .or. size(fld5,dim=2) /= fldszd2 .or. size(fld5,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld5 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fracwgt)) then
       if (size(fracwgt,dim=1) /= fldszd1 .or. size(fracwgt,dim=2) /= fldszd2) then
          write(nulprt,*) subname,estr,'fracwgt size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if

    if (prism_var(var_id)%num > 1) then
    ! treat data as 2d bundled data

       if (size(fld1,dim=3) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 3rd dim size = ',size(fld1,dim=3)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

       ns = size(fld1,dim=1)*size(fld1,dim=2)
       if (present(fracwgt)) then
          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n), fld3(:,:,n), fld4(:,:,n), fld5(:,:,n),     &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,:))
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n), fld3(:,:,n), fld4(:,:,n),                  &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,:))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n), fld3(:,:,n),                               &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,:))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n),                                            &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,:))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,:))
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
             endif
          enddo
       else
          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n), fld3(:,:,n), fld4(:,:,n), fld5(:,:,n),     &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n), fld3(:,:,n), fld4(:,:,n),                  &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n), fld3(:,:,n),                               &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n),                                            &
                     write_restart=write_restart, varnum=n)
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     write_restart=write_restart, varnum=n)
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
             endif
          enddo
       endif

    else
    ! treat as 3d data
       if (present(fracwgt)) then
          write(nulprt,*) subname,estr,' fracwgt shape incorrect in oasis_put'
          call oasis_abort(file=__FILE__,line=__LINE__)
       else

          ns = size(fld1)
          if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3, fld4, fld5,                          &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3, fld4,                                &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3,                                      &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2,                                            &
                  write_restart=write_restart)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  write_restart=write_restart)
          else
             write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
             call oasis_abort(file=__FILE__,line=__LINE__)
          endif

       endif

    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_put_r38f2

!---------------------------------------------------------------------

!> Send 8 byte real 2D bundled data with bundled fracwgt or 3D data with fracwgt

  SUBROUTINE oasis_put_r38f3(var_id,kstep,fld1,kinfo, &
    fld2, fld3, fld4, fld5, write_restart, fracwgt)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_double_p) :: fld1(:,:,:)             !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    real(kind=ip_double_p), optional :: fld2(:,:,:)   !< higher order field data
    real(kind=ip_double_p), optional :: fld3(:,:,:)   !< higher order field data
    real(kind=ip_double_p), optional :: fld4(:,:,:)   !< higher order field data
    real(kind=ip_double_p), optional :: fld5(:,:,:)   !< higher order field data
    logical               , optional :: write_restart !< write restart now
    real(kind=ip_double_p)           :: fracwgt(:,:,:)!< dynamic fraction weight
    !-------------------------------------
    integer(kind=ip_i4_p) :: n, ns, fldszd1, fldszd2, fldszd3
    character(len=*),parameter :: subname = '(oasis_put_r38f3)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    ! check consistency of fld sizes
    fldszd1 = size(fld1,dim=1)
    fldszd2 = size(fld1,dim=2)
    fldszd3 = size(fld1,dim=3)
    if (present(fld2)) then
       if (size(fld2,dim=1) /= fldszd1 .or. size(fld2,dim=2) /= fldszd2 .or. size(fld2,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld2 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld3)) then
       if (size(fld3,dim=1) /= fldszd1 .or. size(fld3,dim=2) /= fldszd2 .or. size(fld3,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld3 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld4)) then
       if (size(fld4,dim=1) /= fldszd1 .or. size(fld4,dim=2) /= fldszd2 .or. size(fld4,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld4 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
    if (present(fld5)) then
       if (size(fld5,dim=1) /= fldszd1 .or. size(fld5,dim=2) /= fldszd2 .or. size(fld5,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fld5 size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
    end if
!    if (present(fracwgt)) then
       if (size(fracwgt,dim=1) /= fldszd1 .or. size(fracwgt,dim=2) /= fldszd2 .or. size(fracwgt,dim=3) /= fldszd3) then
          write(nulprt,*) subname,estr,'fracwgt size /= fld size ',trim(prism_var(var_id)%name)
          call oasis_abort(file=__FILE__,line=__LINE__)
       end if
!    end if

    if (prism_var(var_id)%num > 1) then
    ! treat data as 2d bundled data, fracwgt same shape

       if (size(fld1,dim=3) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 3rd dim size = ',size(fld1,dim=3)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

!       if (present(fracwgt)) then
          ns = size(fld1,dim=1)*size(fld1,dim=2)
          do n = 1,prism_var(var_id)%num
             if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n), fld3(:,:,n), fld4(:,:,n), fld5(:,:,n),     &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,:,n))
             elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n), fld3(:,:,n), fld4(:,:,n),                  &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,:,n))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n), fld3(:,:,n),                               &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,:,n))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     fld2(:,:,n),                                            &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,:,n))
             elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
                call oasis_put_worker(var_id, kstep, fld1(:,:,n), ns, kinfo, &
                     write_restart=write_restart, varnum=n, fracwgt=fracwgt(:,:,n))
             else
                write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
                call oasis_abort(file=__FILE__,line=__LINE__)
             endif
          enddo
!       endif

    else
    ! treat data as 3d unbundled data, fracwgt same shape
!       if (present(fracwgt)) then
          ns = size(fld1)
          if (present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3, fld4, fld5,                          &
                  write_restart=write_restart,fracwgt=fracwgt)
          elseif (.not.present(fld5) .and. present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3, fld4,                                &
                  write_restart=write_restart,fracwgt=fracwgt)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2, fld3,                                      &
                  write_restart=write_restart,fracwgt=fracwgt)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  fld2,                                            &
                  write_restart=write_restart,fracwgt=fracwgt)
          elseif (.not.present(fld5) .and. .not.present(fld4) .and. .not.present(fld3) .and. .not.present(fld2)) then
             call oasis_put_worker(var_id, kstep, fld1, ns, kinfo, &
                  write_restart=write_restart,fracwgt=fracwgt)
          else
             write(nulprt,*) subname,estr,' Wrong field array argument list in oasis_put'
             call oasis_abort(file=__FILE__,line=__LINE__)
          endif
!       endif

    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_put_r38f3

!-------------------------------------------------------------------

!> Send worker routine puts 8 byte real 1D data

  SUBROUTINE oasis_put_worker(var_id,kstep,fld1,ns,kinfo, &
    fld2, fld3, fld4, fld5, write_restart, varnum, fracwgt)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_double_p)             :: fld1(ns)    !< field data
    integer(kind=ip_i4_p) , intent(in) :: ns          !< array size
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    real(kind=ip_double_p), optional :: fld2(ns)      !< higher order field data
    real(kind=ip_double_p), optional :: fld3(ns)      !< higher order field data
    real(kind=ip_double_p), optional :: fld4(ns)      !< higher order field data
    real(kind=ip_double_p), optional :: fld5(ns)      !< higher order field data
    logical               , optional :: write_restart !< write restart now
    integer(kind=ip_i4_p) , optional :: varnum        !< varnum in bundled field
    real(kind=ip_double_p), optional :: fracwgt(ns)   !< dynamic fraction weight
    !-------------------------------------
    integer(kind=ip_i4_p) :: nfld,ncpl
    integer(kind=ip_i4_p) :: nsx
    integer(kind=ip_i4_p) :: lvarnum
    logical :: a2on, a3on, a4on, a5on, fwon
    logical :: lwrst
    character(len=*),parameter :: subname = '(oasis_put_worker)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    if (.not. enddef_called) then
       write(nulprt,*) subname,estr,'called before oasis_enddef'
       call oasis_abort(file=__FILE__,line=__LINE__)
    endif

    if (var_id == OASIS_Var_Uncpl) then
       write(nulprt,*) subname,estr,'oasis_put is called for a variable not in namcouple'
       call oasis_abort(file=__FILE__,line=__LINE__)
       call oasis_debug_exit(subname)
       return
    endif

    if (var_id < 1 .or. var_id > prism_nvar) then
       write(nulprt,*) subname,estr,'oasis_put is called for a variable not defined'
       call oasis_abort(file=__FILE__,line=__LINE__)
       call oasis_debug_exit(subname)
       return
    endif

    if (present(write_restart)) then
       lwrst = write_restart
    else
       lwrst = .false.
    endif

    if (present(varnum)) then
       lvarnum = varnum
    else
       lvarnum = 1
    endif

    nfld = var_id
    ncpl  = prism_var(nfld)%ncpl

    if (ncpl <= 0) then
       if (OASIS_debug >= 15) write(nulprt,*) subname,' variable not coupled ',&
                              trim(prism_var(nfld)%name)
       call oasis_debug_exit(subname)
       return
    endif

    a2on = present(fld2)
    a3on = present(fld3)
    a4on = present(fld4)
    a5on = present(fld5)
    fwon = present(fracwgt)

    ! check that arguments 2-5 passed are OK, cannot have 3 without 2, etc
    if (((.not. a2on) .and. ((a3on) .or. (a4on) .or. (a5on))) .or. &
        ((.not. a3on) .and. ((a4on) .or. (a5on)            )) .or. &
        ((.not. a4on) .and. ((a5on)                        ))) then
        write(nulprt,*) subname,estr,' Incorrect field array 2-5 argument list in oasis_put'
        call oasis_abort(file=__FILE__,line=__LINE__)
    endif

    call oasis_advance_run(OASIS_Out,nfld,kstep,kinfo,&
                           array1din=fld1,readrest=.FALSE.,&
                           a2on=a2on,array2=fld2,&
                           a3on=a3on,array3=fld3,&
                           a4on=a4on,array4=fld4,&
                           a5on=a5on,array5=fld5,&
                           fwon=fwon,fracwgt=fracwgt,writrest=lwrst,varnum=lvarnum)

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_put_worker

!-------------------------------------------------------------------
!---------------------------------------------------------------------
#ifndef __NO_4BYTE_REALS 

!> Receive 4 byte real 1D data

  SUBROUTINE oasis_get_r14(var_id,kstep,fld,kinfo)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id     !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep      !< model time in seconds
    real(kind=ip_single_p), intent(inout) :: fld(:)  !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo      !< return code
    !-------------------------------------
    integer(kind=ip_i4_p) :: ns
    real(kind=ip_r8_p), allocatable :: array(:)
    character(len=*),parameter :: subname = '(oasis_get_r14)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    if (prism_var(var_id)%num > 1) then
       write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
       write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
       call oasis_abort(file=__FILE__,line=__LINE__)
    endif

    ns = size(fld,dim=1)
    allocate(array(ns))

    call oasis_get_worker(var_id,kstep,array,ns,kinfo)

    if (kinfo /= OASIS_OK) then
       fld(:) = real(array(:),kind=ip_single_p)
    endif

    deallocate(array)

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_get_r14
#endif

!---------------------------------------------------------------------

!> Receive 8 byte real 1D data

  SUBROUTINE oasis_get_r18(var_id,kstep,fld,kinfo)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id     !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep      !< model time in seconds
    real(kind=ip_r8_p)    , intent(inout) :: fld(:)  !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo      !< return code
    !-------------------------------------
    integer(kind=ip_i4_p) :: ns
    character(len=*),parameter :: subname = '(oasis_get_r18)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    if (prism_var(var_id)%num > 1) then
       write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
       write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
       call oasis_abort(file=__FILE__,line=__LINE__)
    endif

    ns = size(fld)

    call oasis_get_worker(var_id,kstep,fld,ns,kinfo)

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_get_r18

!---------------------------------------------------------------------
#ifndef __NO_4BYTE_REALS

!> Receive 4 byte real 2D data

  SUBROUTINE oasis_get_r24(var_id,kstep,fld,kinfo)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_single_p), intent(inout) :: fld(:,:) !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    !-------------------------------------
    integer(kind=ip_i4_p) :: ns,nis,njs,n
    real(kind=ip_r8_p), allocatable :: array(:),array2(:,:)
    character(len=*),parameter :: subname = '(oasis_get_r24)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    if (prism_var(var_id)%num > 1) then
    ! treat as 1d bundled data
       if (size(fld,dim=2) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 2nd dim size = ',size(fld,dim=2)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

       ns = size(fld,dim=1)
       allocate(array(ns))

       do n = 1,prism_var(var_id)%num
          kinfo = OASIS_OK
          call oasis_get_worker(var_id,kstep,array,ns,kinfo,varnum=n)
          if (kinfo /= OASIS_OK) then
             fld(:,n) = real(array(:),kind=ip_single_p)
          endif
       enddo

       deallocate(array)

    else
    ! treat as 2d unbundled data

       nis = size(fld,dim=1)
       njs = size(fld,dim=2)
       ns = nis*njs

       allocate(array2(nis,njs))

       call oasis_get_worker(var_id,kstep,array2,ns,kinfo)

       if (kinfo /= OASIS_OK) then
          fld = real(array2,kind=ip_single_p)
       endif

       deallocate(array2)

    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_get_r24
#endif

!---------------------------------------------------------------------
#ifndef __NO_4BYTE_REALS

!> Receive 4 byte real 3D bundled data

  SUBROUTINE oasis_get_r34(var_id,kstep,fld,kinfo)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_single_p), intent(inout) :: fld(:,:,:) !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    !-------------------------------------
    integer(kind=ip_i4_p) :: ns,nis,njs,nks,n
    real(kind=ip_r8_p), allocatable :: array2(:,:),array3(:,:,:)
    character(len=*),parameter :: subname = '(oasis_get_r34)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    if (prism_var(var_id)%num > 1) then
    ! treat as 2d bundled data
       if (size(fld,dim=3) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 3rd dim size = ',size(fld,dim=3)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

       nis = size(fld,dim=1)
       njs = size(fld,dim=2)
       ns = nis*njs

       allocate(array2(nis,njs))

       do n = 1,prism_var(var_id)%num
          kinfo = OASIS_OK
          call oasis_get_worker(var_id,kstep,array2,ns,kinfo,varnum=n)
          if (kinfo /= OASIS_OK) then
             fld(:,:,n) = real(array2(:,:),kind=ip_single_p)
          endif
       enddo

       deallocate(array2)

    else
    ! treat as 3d unbundled data
 
       nis = size(fld,dim=1)
       njs = size(fld,dim=2)
       nks = size(fld,dim=3)
       ns = nis*njs*nks

       allocate(array3(nis,njs,nks))

       call oasis_get_worker(var_id,kstep,array3,ns,kinfo)

       if (kinfo /= OASIS_OK) then
          fld(:,:,:) = real(array3,kind=ip_single_p)
       endif

       deallocate(array3)

    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_get_r34
#endif

!---------------------------------------------------------------------

!> Receive 8 byte real 2D data

  SUBROUTINE oasis_get_r28(var_id,kstep,fld,kinfo)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_double_p), intent(inout) :: fld(:,:) !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    !-------------------------------------
    integer(kind=ip_i4_p) :: ns,nis,njs,n
    character(len=*),parameter :: subname = '(oasis_get_r28)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    if (prism_var(var_id)%num > 1) then
    ! treat as 1d bundled data
       if (size(fld,dim=2) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 2nd dim size = ',size(fld,dim=2)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

       ns = size(fld,dim=1)

       do n = 1,prism_var(var_id)%num
          call oasis_get_worker(var_id,kstep,fld(:,n),ns,kinfo,varnum=n)
       enddo

    else
    ! treat as 2d unbundled data

       nis = size(fld,dim=1)
       njs = size(fld,dim=2)
       ns = nis*njs

       call oasis_get_worker(var_id,kstep,fld,ns,kinfo)

    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_get_r28

!---------------------------------------------------------------------

!> Receive 8 byte real 3D bundled data

  SUBROUTINE oasis_get_r38(var_id,kstep,fld,kinfo)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id      !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep       !< model time in seconds
    real(kind=ip_double_p), intent(inout) :: fld(:,:,:) !< field data
    integer(kind=ip_i4_p) , intent(out):: kinfo       !< return code
    !-------------------------------------
    integer(kind=ip_i4_p) :: ns,nis,njs,nks,n
    character(len=*),parameter :: subname = '(oasis_get_r38)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    if (prism_var(var_id)%num > 1) then
    ! treat as 2d bundled data
       if (size(fld,dim=3) /= prism_var(var_id)%num) then
          write(nulprt,*) subname,estr,'called for variable ',trim(prism_var(var_id)%name)
          write(nulprt,*) subname,estr,'expecting bundled field with num = ',prism_var(var_id)%num
          write(nulprt,*) subname,estr,'passing in field with incorrect 3rd dim size = ',size(fld,dim=3)
          call oasis_abort(file=__FILE__,line=__LINE__)
       endif

       nis = size(fld,dim=1)
       njs = size(fld,dim=2)
       ns = nis*njs

       do n = 1,prism_var(var_id)%num
          call oasis_get_worker(var_id,kstep,fld(:,:,n),ns,kinfo,varnum=n)
       enddo

    else
    ! treat as 3d unbundled data

       nis = size(fld,dim=1)
       njs = size(fld,dim=2)
       nks = size(fld,dim=3)
       ns = nis*njs*nks

       call oasis_get_worker(var_id,kstep,fld,ns,kinfo)

    endif

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_get_r38

!-------------------------------------------------------------------
!> Receive subroutine that actually does the work on 8 byte 1D data

  SUBROUTINE oasis_get_worker(var_id,kstep,fld,ns,kinfo,varnum)

    implicit none
    !-------------------------------------
    integer(kind=ip_i4_p) , intent(in) :: var_id     !< variable id
    integer(kind=ip_i4_p) , intent(in) :: kstep      !< model time in seconds
    real(kind=ip_double_p), intent(inout) :: fld(ns) !< field data
    integer(kind=ip_i4_p) , intent(in) :: ns         !< size of data field
    integer(kind=ip_i4_p) , intent(out):: kinfo      !< return code
    integer(kind=ip_i4_p) , optional   :: varnum     !< variable num in bundled field
    !-------------------------------------
    integer(kind=ip_i4_p) :: nfld,ncpl
    integer(kind=ip_i4_p) :: lvarnum
    character(len=*),parameter :: subname = '(oasis_get_worker)'
    !-------------------------------------

    call oasis_debug_enter(subname)
    kinfo = OASIS_OK
    if (.not. oasis_coupled) then
       call oasis_debug_exit(subname)
       return
    endif

    if (.not. enddef_called) then
       write(nulprt,*) subname,estr,'called before oasis_enddef'
       call oasis_abort(file=__FILE__,line=__LINE__)
    endif

    if (var_id == OASIS_Var_Uncpl) then
       write(nulprt,*) subname,estr,'oasis_get is called for a variable not in namcouple'
       write(nulprt,*) subname,' BE CAREFUL NOT TO USE IT !!!!!'
       call oasis_abort(file=__FILE__,line=__LINE__)
       call oasis_debug_exit(subname)
       return
    endif

    if (var_id < 1 .or. var_id > prism_nvar) then
       write(nulprt,*) subname,estr,'oasis_get is called for a variable not defined'
       call oasis_abort(file=__FILE__,line=__LINE__)
       call oasis_debug_exit(subname)
       return
    endif

    if (present(varnum)) then
       lvarnum = varnum
    else
       lvarnum = 1
    endif

    nfld = var_id
    ncpl  = prism_var(nfld)%ncpl

    if (ncpl <= 0) then
       if (OASIS_debug >= 15) write(nulprt,*) subname,' variable not coupled ',&
                              trim(prism_var(nfld)%name)
       call oasis_debug_exit(subname)
       return
    endif

    call oasis_advance_run(OASIS_In,nfld,kstep,kinfo,array1dout=fld,readrest=.FALSE.,varnum=lvarnum)

    call oasis_debug_exit(subname)

  END SUBROUTINE oasis_get_worker

!-------------------------------------------------------------------

END MODULE mod_oasis_getput_interface

