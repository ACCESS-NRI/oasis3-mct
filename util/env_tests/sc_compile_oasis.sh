################################################
# Compilation of OASIS or PYOASIS
###############################################
cd ${OASIS_COUPLE}/util/make_dir
make realclean -f ${OASIS_COUPLE}/util/make_dir/TopMakefileOasis3
make -f ${OASIS_COUPLE}/util/make_dir/TopMakefileOasis3 $OASIS_TARGET

if [ -z "${OASIS_TARGET}" ]; then
# results in INSTALL_OASIS.${OASIS_ENV}: build-static  include  lib
#
ls ${OASIS_COUPLE}/INSTALL_OASIS.${OASIS_ENV}/lib/libmct.a
if [ `echo $?` -ne 0 ]; then
    echo "pb libmct.a not created"
    exit 1
fi
ls ${OASIS_COUPLE}/INSTALL_OASIS.${OASIS_ENV}/lib/libmpeu.a
res_command=`echo $?`
if [ ${res_command} -ne 0 ]; then
    echo "pb libmpeu.a  not created"
    exit 1
fi
ls ${OASIS_COUPLE}/INSTALL_OASIS.${OASIS_ENV}/lib/libscrip.a
res_command=`echo $?`
if [ ${res_command} -ne 0 ]; then
    echo "libpsmile.MPI1.a not created"
    exit 1
fi
ls ${OASIS_COUPLE}/INSTALL_OASIS.${OASIS_ENV}/lib/libpsmile.MPI1.a
res_command=`echo $?`
if [ ${res_command} -ne 0 ]; then
    echo "libscrip.a not created"
    exit 1
fi
else
# results in INSTALL_OASIS.${OASIS_ENV} : build-shared  include  lib  python
#
ls ${OASIS_COUPLE}/INSTALL_OASIS.${OASIS_ENV}/lib/libmct.so
if [ `echo $?` -ne 0 ]; then
    echo "pb libmct.a not created"
    exit 1
fi
ls ${OASIS_COUPLE}/INSTALL_OASIS.${OASIS_ENV}/lib/libmpeu.so
res_command=`echo $?`
if [ ${res_command} -ne 0 ]; then
    echo "pb libmpeu.a  not created"
    exit 1
fi
ls ${OASIS_COUPLE}/INSTALL_OASIS.${OASIS_ENV}/lib/libscrip.so
res_command=`echo $?`
if [ ${res_command} -ne 0 ]; then
    echo "libpsmile.MPI1.a not created"
    exit 1
fi
ls ${OASIS_COUPLE}/INSTALL_OASIS.${OASIS_ENV}/lib/libpsmile.MPI1.so
res_command=`echo $?`
if [ ${res_command} -ne 0 ]; then
    echo "libscrip.a not created"
    exit 1
fi
ls ${OASIS_COUPLE}/INSTALL_OASIS.${OASIS_ENV}/lib/liboasis.cbind.so
res_command=`echo $?`
if [ ${res_command} -ne 0 ]; then
    echo "libscrip.a not created"
    exit 1
fi
#
# End else test on pyoasis
fi
