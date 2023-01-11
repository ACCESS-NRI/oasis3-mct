################################################
# Compilation of OASIS or PYOASIS
###############################################
cd ${OASIS_COUPLE}/util/make_dir
make realclean -f ${OASIS_COUPLE}/util/make_dir/TopMakefileOasis3
make -f ${OASIS_COUPLE}/util/make_dir/TopMakefileOasis3 $OASIS_TARGET

# ATTENTION : si oasis3-mct librairies statiques
# sinon verification creation de 
# libmct.so  libmpeu.so  liboasis.cbind.so  libpsmile.MPI1.so  libscrip.so
ls ${OASIS_COUPLE}/INSTALL_OASIS.${OASIS_ENV}/lib/libmct.a
# A tester
#res_command=`echo $?`
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
