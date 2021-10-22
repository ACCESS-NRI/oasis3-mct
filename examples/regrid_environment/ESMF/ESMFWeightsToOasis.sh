#!/bin/ksh

# Convert ESMF weight file in OASIS format
echo -e "--\nConvert ESMF weight file in OASIS format"

output_weightdir="."
mkdir $output_weightdir

sgrid=$1
dgrid=$2
method=$3

case $method in
    bilinear) meth_convname=BILINEAR ;;
    patch) meth_convname=PATCH ;;
    neareststod) meth_convname=DISTWGT_1 ;;
    conserve_destarea) meth_convname=CONSERV_DESTAREA ;;
    conserve2nd_destarea) meth_convname=CONS2ND_DESTAREA ;;
    conserve_fracarea) meth_convname=CONSERV_FRACAREA ;;
    conserve2nd_fracarea) meth_convname=CONS2ND_FRACAREA ;;
esac
fweights_oasis=rmp_${sgrid}_to_${dgrid}_esmf_${meth_convname}.nc
rm -f ${fweights_oasis}
ncap2 -h -s 'remap_matrix[$n_s,$num_wgts]=S' ESMFweights.nc work.nc   # create variable remap_matrix from S with one more dimension
ncks -h -x -v S,yc_a,yc_b,xc_a,xc_b,yv_a,yv_b,xv_a,xv_b,area_a,area_b,frac_a,frac_b,src_grid_dims,dst_grid_dims work.nc ${fweights_oasis}
ncrename -h -d n_a,src_grid_size ${fweights_oasis}
ncrename -h -d n_b,dst_grid_size ${fweights_oasis}
ncrename -h -d n_s,num_links ${fweights_oasis}
ncrename -h -v mask_a,src_grid_imask ${fweights_oasis}
ncrename -h -v mask_b,dst_grid_imask ${fweights_oasis}
ncrename -h -v col,src_address ${fweights_oasis}
ncrename -h -v row,dst_address ${fweights_oasis}
rm -f work.nc
ln -sf ${fweights_oasis} rmp_${sgrid}_${dgrid}.nc
#mv ${fweights_oasis} ${output_weightdir}

