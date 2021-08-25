This version is the master branch of the OASIS3-MCT climate coupler. It will contain the future developments for OASIS3-MCT_5.0

Since the first developments of OASIS3-MCT, it includes:
- Update CHECKIN CHECKOUT diagnostics, add masked + weighted means and sum
- Add $NCDFTYP namcouple control of NetCDF file types. Options are cdf1, cdf2, and cdf5. Default is cdf1, "classic" mode. cdf2 was tested on nemo and successfully changed the format of the output, restart, and mapping files. cdf5 requires a CPP CDF_64BIT_DATA to be set.
- A bug fix when generating the remapping files with SCRIP : if we have fields which require BICUBIC weights followed by fields which require BILINEAR weights, then the BILINEAR weights are corrupted. However if we do things in a different order: BILINEAR first followed by BICUBIC, then things are OK. This problem was solved (ticket 2725)
- A first beta version of Python API available (STFC)
- Add ability to set north and south thresholds on the SCRIPR CONSERV namcouple line. 
- Add number of neighbors to the mapping filename for DISTWGT and GAUSWGT mapping files 
- A « True » area normalisation in conservative remapping
- An addition of “additional nearest-neighbour” option in SCRIP CONSERV/DESTAREA (DESTNNEI, DESTNNTR)
- The possibility to deactivate the “additional nearest-neighbour” option (BILINEARNF, BICUBICNF, DISTWGTNF, and GAUSWGTNF)
- A bugfix for local distance calculation in DISTWGT and GAUSWGT interpolation
- More systematic test of NetCDF returned error code
- Fractional masks for the global conservation operation CONSERV (ESiWACE2)
- New options in global CONSERV to conserve fields with positive and negative values with average value close to zero (ESiWACE2)
- An hybrid MPI+OpenMP parallelisation of the SCRIP library (previously fully sequential) leading to great reduction in the offline calculation
- A new communication method, using the remapping weights to define the intermediate mapping decomposition, offering a significant gain at run
- New methods introduced in the global CONSERV operation reducing its costs by one order of magnitude while still ensuring an appropriate level
- Support for bundle coupling fields;
- Automatic coupling restart writing;
- Memory and performance upgrades;
- A new LUCIA tool for load balancing analysis;
- New memory tracking tool (gilt);
- Improved error checking and error messages;
- Expanded test cases and testing automation;
- Testing at high resolution (> 1M gridpoints), high processor counts (32k pes), and with large variable counts (> 1k coupling fields);
- Bicubic and Second Order Conservative interpolations (with the gradients of the fields being provided by the models);
- Exchange of data on only a subdomain of the global grid;
- The specification of how time statistics are written out (variable TIMER_Debug) in the configuration file “namcouple”;
- Abilty to normalize the conservative remapping weights by the true areas of the grid using gridcell fraction
- New CONSERV options to normalize postive and negative values separately

Please keep us informed of your progress with OASIS3-MCT and do not forget to cite the following latest reference in your paper describing your coupled model results.::
A. Craig, S. Valcke, L. Coquart, 2017: Development and performance of a new version of the OASIS coupler, OASIS3-MCT_3.0, Geosci. Model Dev., 10, 3297-3308,https://doi.org/10.5194/gmd-10-3297-2017, 2017.   

If you have problems or questions, please check the forum on the OASIS3-MCT web site (https://portal.enes.org/oasis) or contact us at oasishelp@cerfacs.fr .
