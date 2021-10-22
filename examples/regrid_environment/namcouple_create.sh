#!/bin/ksh
#set -x

host=`uname -n`
user=`whoami`

## - Define paths
srcdir=`pwd`
casename=`basename $srcdir`

## - Define case

SGRID=$1
TGRID=$2
remap=$3
n_p_t=$4
nnode=`echo $n_p_t | awk -F _ '{print $1}'`
mpiprocs=`echo $n_p_t | awk -F _ '{print $2}'`
threads=`echo $n_p_t | awk -F _ '{print $3}'`
library=$5
ext=$6

## - Define rundir
rundir=$srcdir/RUNDIR_${library}_${ext}/${casename}_${SGRID}_${TGRID}_${remap}_${nnode}_${mpiprocs}_${threads}_${library}_${ext}

## - Create namcouple
if [ ${library} == "SCRP" ]; then
    nname=${rundir}/namcouple_${SGRID}_${TGRID}_${remap}
else
    nname=${rundir}/namcouple_${SGRID}_${TGRID}
fi
#
if [ ${SGRID} == "bggd" ]; then
    SRCDIMI=144 ; SRCDIMJ=143 ; STYPE=LR ; SRCP=P ; SRCPN=0 
elif [ ${SGRID} == "ssea" ]; then
    SRCDIMI=24572 ; SRCDIMJ=1 ; STYPE=D ; SRCP=P ; SRCPN=0
elif [ ${SGRID} == "icos" ]; then
    SRCDIMI=15212 ; SRCDIMJ=1 ; STYPE=U ; SRCP=P ; SRCPN=0
elif [ ${SGRID} == "icoh" ]; then
    SRCDIMI=2016012 ; SRCDIMJ=1 ; STYPE=U ; SRCP=P ; SRCPN=0   
elif [ ${SGRID} == "nogt" ]; then
    SRCDIMI=362 ; SRCDIMJ=294 ; STYPE=LR ; SRCP=P ; SRCPN=2
elif [ ${SGRID} == "t12e" ]; then
    SRCDIMI=4322 ; SRCDIMJ=3147 ; STYPE=LR ; SRCP=P ; SRCPN=2
fi
if [ ${TGRID} == "bggd" ]; then
    TGTDIMI=144 ; TGTDIMJ=143 ; TTYPE=LR ; TGTP=P ; TGTPN=0   
elif [ ${TGRID} == "ssea" ]; then
    TGTDIMI=24572 ; TGTDIMJ=1 ; TTYPE=D ; TGTP=P ; TGTPN=0
elif [ ${TGRID} == "icos" ]; then
    TGTDIMI=15212 ; TGTDIMJ=1 ; TTYPE=U ; TGTP=P ; TGTPN=0
elif [ ${TGRID} == "icoh" ]; then
    TGTDIMI=2016012 ; TGTDIMJ=1 ; TTYPE=U ; TGTP=P ; TGTPN=0   
elif [ ${TGRID} == "nogt" ]; then
    TGTDIMI=362 ; TGTDIMJ=294 ; TTYPE=LR ; TGTP=P ; TGTPN=2
elif [ ${TGRID} == "t12e" ]; then
    TGTDIMI=4322 ; TGTDIMJ=3147 ; TTYPE=LR ; TGTP=P ; TGTPN=2
fi
##
if [ ${library} == "SCRP" ]; then
    if [ ${remap} == "distwgt" ]; then
	scripmethod=DISTWGT
    elif [ ${remap} == "bili" ]; then
	scripmethod=BILINEAR
    elif [ ${remap} == "bicu" ]; then
	scripmethod=BICUBIC	
    elif [ ${remap} == "conserv1st" ] ; then
	scripmethod=CONSERV ; scriporder=FIRST
    elif [ ${remap} == "conserv2nd" ] ; then
	scripmethod=CONSERV ; scriporder=SECOND
    fi
fi

cat <<EOF > $nname
\$NFIELDS
1
\$END
\$RUNTIME
1
\$END 
\$NLOGPRT
1 0
\$END
############################################ 
\$STRINGS
FSENDANA FRECVANA 1 1 1 rst.nc EXPOUT
EOF
##
cat <<EOF >> $nname
$SRCDIMI $SRCDIMJ $TGTDIMI $TGTDIMJ $SGRID $TGRID
$SRCP $SRCPN $TGTP $TGTPN
EOF
##
if [ ${library} == "SCRP" ]; then
    cat <<EOF >> $nname
SCRIPR
EOF
    if [ ${remap} == "distwgt" ]; then
	cat <<EOF >> $nname
${scripmethod} ${STYPE} SCALAR LATITUDE 1 1
EOF
    elif [ ${remap} == "bili" ] || [ ${remap} == "bicu" ]; then
	cat <<EOF >> $nname
${scripmethod} ${STYPE} SCALAR LATITUDE 1
EOF
    elif [ ${remap} == "conserv1st" ]; then
	cat <<EOF >> $nname
CONSERV ${STYPE} SCALAR LATITUDE 1 FRACAREA FIRST
EOF
    elif [ ${remap} == "conserv2nd" ]; then
	cat <<EOF >> $nname
CONSERV ${STYPE} SCALAR LATITUDE 1 FRACAREA SECOND
EOF
	
    fi		
else
    cat	<<EOF >> $nname
MAPPING
rmp_${SGRID}_${TGRID}.nc
EOF
fi
    
cat <<EOF >> $nname
\$END
EOF

mv ${nname} ${rundir}/namcouple



