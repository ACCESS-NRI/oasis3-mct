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
method=`echo $remap | awk -F _ '{print $1}'`
order=`echo $remap | awk -F _ '{print $2}'`
normalization=`echo $remap | awk -F _ '{print $3}'`
fana=$4
n_p_t=$5
nnode=`echo $n_p_t | awk -F _ '{print $1}'`
mpiprocs=`echo $n_p_t | awk -F _ '{print $2}'`
threads=`echo $n_p_t | awk -F _ '{print $3}'`
library=$6
ext=$7

## - Define rundir
rundir=$srcdir/RUNDIR_${library}_${ext}/${casename}_${SGRID}_${TGRID}_${remap}_${fana}_${n_p_t}_${library}_${ext}

## - Create namcouple
if [ ${library} == "SCRP" ]; then
    nname=${rundir}/namcouple_${SGRID}_${TGRID}_${method}${order}
else
    nname=${rundir}/namcouple_${SGRID}_${TGRID}
fi
#
if [ ${SGRID} == "bggd" ]; then
    SRCDIMI=144 ; SRCDIMJ=143 ; STYPE=LR ; SRCP=P ; SRCPN=0 
elif [ ${SGRID} == "sse7" ]; then
    SRCDIMI=24572 ; SRCDIMJ=1 ; STYPE=D ; SRCP=P ; SRCPN=0
elif [ ${SGRID} == "icos" ]; then
    SRCDIMI=15212 ; SRCDIMJ=1 ; STYPE=U ; SRCP=P ; SRCPN=0
elif [ ${SGRID} == "icoh" ]; then
    SRCDIMI=2016012 ; SRCDIMJ=1 ; STYPE=U ; SRCP=P ; SRCPN=0   
elif [ ${SGRID} == "nogt" ]; then
    SRCDIMI=362 ; SRCDIMJ=294 ; STYPE=LR ; SRCP=P ; SRCPN=2
elif [ ${SGRID} == "torc" ]; then
    SRCDIMI=182 ; SRCDIMJ=149 ; STYPE=LR ; SRCP=P ; SRCPN=2    
fi
if [ ${TGRID} == "bggd" ]; then
    TGTDIMI=144 ; TGTDIMJ=143 ; TTYPE=LR ; TGTP=P ; TGTPN=0   
elif [ ${TGRID} == "sse7" ]; then
    TGTDIMI=24572 ; TGTDIMJ=1 ; TTYPE=D ; TGTP=P ; TGTPN=0
elif [ ${TGRID} == "icos" ]; then
    TGTDIMI=15212 ; TGTDIMJ=1 ; TTYPE=U ; TGTP=P ; TGTPN=0
elif [ ${TGRID} == "icoh" ]; then
    TGTDIMI=2016012 ; TGTDIMJ=1 ; TTYPE=U ; TGTP=P ; TGTPN=0   
elif [ ${TGRID} == "nogt" ]; then
    TGTDIMI=362 ; TGTDIMJ=294 ; TTYPE=LR ; TGTP=P ; TGTPN=2
elif [ ${TGRID} == "torc" ]; then
    TGTDIMI=182 ; TGTDIMJ=149 ; TTYPE=LR ; TGTP=P ; TGTPN=2    
fi
##
if [ ${library} == "SCRP" ]; then
    if [ ${method} == "distwgt" ]; then
	scripmethod=DISTWGT
    elif [ ${method} == "bili" ]; then
	scripmethod=BILINEAR
    elif [ ${method} == "bicu" ]; then
	scripmethod=BICUBIC	
    elif [ ${method} == "conserv" ] ; then
	scripmethod=CONSERV
        case $order in
            1st) scriporder=FIRST ;;
            2nd) scriporder=SECOND ;;
        esac
        scripnorm=`echo ${normalization} | tr '[:lower:]' '[:upper:]'`
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
    if [ ${method} == "distwgt" ]; then
	cat <<EOF >> $nname
${scripmethod} ${STYPE} SCALAR LATITUDE 1 1
EOF
    elif [ ${method} == "bili" ] || [ ${method} == "bicu" ]; then
	cat <<EOF >> $nname
${scripmethod} ${STYPE} SCALAR LATITUDE 1
EOF
    elif [ ${method} == "conserv" ]; then
	cat <<EOF >> $nname
${scripmethod} ${STYPE} SCALAR LATITUDE 1 ${scripnorm} ${scriporder}
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



