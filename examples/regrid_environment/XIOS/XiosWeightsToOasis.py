#!/usr/bin/env python3

import os, time
import netCDF4
import numpy as np
import xml.etree.ElementTree as ET

def convert_Xios_to_Oasis(path_out="."):

    iodefxml = ET.parse('iodef.xml')
    iodef = iodefxml.getroot()
    
    for variable in iodef.iter('variable'):
        if variable.get('id') == 'src_domain':
            src_grid = variable.text.strip()
        if variable.get('id') == 'tgt_domain':
            dst_grid = variable.text.strip()
    
    contextfile = 'context_toy.xml'
    for child in iodef.iter('context'):
        if child.get('src'):
            contextfile = child.get('src')
    
    contextxml = ET.parse(contextfile)
    context = contextxml.getroot()
    
    for idom in context.iter('domain'):
        if idom.get('id') == 'interpolated_domain' and \
           idom.get('domain_ref') == 'tgt_domain':
            idomdef = idom.find('interpolate_domain')
            order = int(idomdef.get('order'))
            fracarea = idomdef.get('renormalize').lower() == 'true'
            truearea = idomdef.get('use_area').lower() == 'true'
            if idomdef.get('write_weight').lower() == 'true':
                remap_file = idomdef.get('weight_filename')
            else:
                print('No remap file has been written by this XIOS instance')
                exit()
            idx_start = 0
            if idomdef.get('read_write_convention').lower() != 'fortran':
                idx_start = 1
    
    if order == 1:
        method = 'CONSERV'
    if order == 2:
        method = 'CONS2ND'
                
    if fracarea:
        normalization='FRACAR'
    else:
        normalization='DESTAR'
    if truearea:
        normalization+='TR'
    else:
        normalization+='EA'
    
    oasisf = 'rmp_'+src_grid+'_to_'+dst_grid+'_xios_'+method+'_'+normalization+'.nc'
    oasisf = os.path.join(path_out, oasisf)
    
    print("Summary:\n--------")
    print("Source grid: {}\nTarget grid: {}\n".format(src_grid, dst_grid))
    print("Order: {}\nFracarea: {}\nTruearea: {}\n".format(order, fracarea, truearea))
    print("Remap input file: {}".format(remap_file))
    print("Remap output file: {}".format(oasisf))
    
    try:
        xiosf_in = netCDF4.Dataset(remap_file, 'r')
    except OSError:
        print("Problem opening XIOS weights file {}".format(remap_file))
        exit()
    
    try:
        oasisf_out = netCDF4.Dataset(oasisf, 'w', format='NETCDF4_CLASSIC')
    except OSError:
        print("Problem creating OASIS-scrip file {}".format(oasisf))
        exit()
    
    # Global attributes
    oasisf_out.title = oasisf
    oasisf_out.normalization = normalization.lower()
    oasisf_out.map_method = "Conservative remapping"
    oasisf_out.remapper = "XIOS"
    oasisf_out.history = 'Created ' + time.ctime(time.time())
    oasisf_out.conventions = "SCRIP"
    
    # Recover dimensions from XIOS File and convert them for OASIS
    oasisf_out.createDimension('src_grid_size', len(xiosf_in.dimensions['n_src']))
    oasisf_out.createDimension('dst_grid_size', len(xiosf_in.dimensions['n_dst']))
    oasisf_out.createDimension('num_links', len(xiosf_in.dimensions['n_weight']))
    oasisf_out.createDimension('num_wgts', 1)
    
    # Create remap matrix
    src_address = oasisf_out.createVariable('src_address', np.int32, ('num_links',))
    dst_address = oasisf_out.createVariable('dst_address', np.int32, ('num_links',))
    remap_matrix = oasisf_out.createVariable('remap_matrix', np.float64, ('num_links', 'num_wgts',))
    
    # Read in XIOS fields
    src_address[:] = xiosf_in.variables['src_idx'][:] + idx_start
    dst_address[:] = xiosf_in.variables['dst_idx'][:] + idx_start
    remap_matrix[:,:] = xiosf_in.variables['weight'][:]
    
    xiosf_in.close()
    oasisf_out.close()

if __name__ == "__main__":
    convert_Xios_to_Oasis()
