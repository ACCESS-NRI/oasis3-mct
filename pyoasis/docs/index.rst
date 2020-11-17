pyOASIS Documentation
=====================

.. toctree::
   :maxdepth: 2
   :caption: Contents:


Introduction
------------

pyOASIS is a Python wrapper for OASIS written using ctypes
and ISO C bindings to Fortran. It provides an object-oriented
interface to OASIS. This allows users to write and couple models
written in Python
or to couple models written in Python with models written
in Fortran.

It is part of the distribution of OASIS. See
http://www.cerfacs.fr/oa4web/oasis3-mct_4.0/oasis3mct_UserGuide.pdf
for more information about obtaining it.

pyOASIS is distributed under the GNU Lesser General Public
License. For more details, see the file lgpl-3.0.txt or
https://www.gnu.org/licenses/lgpl-3.0.en.html.

Installation
------------
The sections between brackets are necessary only when Cartopy plots are required, for the examples 10 and 11.

Under GNU/Linux
+++++++++++++++

Prerequisites
.............

- A Fortran and C compiler suite (tested with version 18 of the Intel compilers as well as versions 7.3, 8.3 and 9 of the GNU compilers).
- An MPI library (tested with version 18 of the Intel MPI Library and versions 4.0.1 and 4.0.5 of OpenMPI)
- NetCDF 4
- Python 3 with mpi4py and NumPy
- [Matplotlib]
- [GEOS (Geometry Engine, Open Source): package libgeos-dev under Debian or Ubuntu]
- [proj: package libproj-dev under Debian or Ubuntu] 

Installation
............
- Obtain OASIS (refer to OASIS User Guide for details).
- Change directory to ${OASIS_ROOT}/util/make_dir.
- Create your own make.inc file based on make.intel_davinci, make.gfortran_openmpi_linux or make.bindings.
- Build and install OASIS and pyOASIS::

    make -f TopMakefile realclean
    make -f TopMakefile pyoasis

- Append the lines displayed at the end of the compilation to your .bashrc file or, alternatively, before using pyOASIS, source the script mentioned there. 

[Extra software]
................

- Create a virtual environment: ::

    export VENVDIR=~/INSTALL/PY_ENV/PyO   directory containing the virtual environment 
    python3 -m venv ${VENVDIR}
    source ${VENVDIR}/bin/activate
    
- Install software: ::

    pip install --upgrade pip
    pip uninstall shapely   
    pip install shapely --no-binary shapely
    pip install cartopy
    pip install pykdtree

The uninstall steps are needed only if a previous version of the software was already there. The last package is not necessary. It is only used for optimisation. 


Under macOS
+++++++++++

Prerequisites
.............

::
   
   brew install gcc   
   brew install openblas
   brew install openmpi 
   [brew install geos]
   [brew install proj]

(This has been tested with gcc 10.2.0.)
   
Installation
............
Same as under GNU/Linux. See previous section.


Virtual Python environment
..........................

- Create a virtual environment:

    Same as under GNU/Linux, see previous section.
    
- Install packages: ::

    pip install mpi4py
    pip uninstall numpy 
    pip cache remove numpy
    OPENBLAS="$(brew --prefix openblas)" pip install --global-option=build-ext numpy
    pip install netcdf4
    [pip uninstall scipy]
    [pip cache remove scipy]
    [pip install --global-option=build-ext scipy]
    [pip uninstall shapely]
    [pip install shapely --no-binary shapely]
    [pip install matplotlib]
    [pip install cartopy]
    [pip install pykdtree]

The uninstall steps are needed only if a previous version of the software was already there. The last package is not necessary. It is only used for optimisation. 


Set up the environment
......................
At the end of your .bashrc, ::

    export TMPDIR=/tmp
    export OMPI_MCA_mca_base_env_list=LD_LIBRARY_PATH=${PYOASIS_ROOT}/lib


Tests
+++++

pyOASIS can be tested by issuing, in the directory ${OASIS_ROOT}/pyoasis::

    make test

This will test the Python wrapper itself as well as running examples using OASIS. It requires pytest.


Documentation
+++++++++++++

If pyOASIS is modified, this document can be regenerated, using Sphinx,
by typing the following command in the directory ${OASIS_ROOT}/pyoasis::
  
   make doc


Using pyOASIS
-------------

Code structure
++++++++++++++

The source code of pyOASIS is in the directory ``src``.
First, the OASIS Fortran code is wrapped in Fortran using ISO-C
bindings. The corresponding source files are in the subdirectory
``src/fortran_isoc``. The file names are the same as the
corresponding ones in the original source code but ending in ``_iso.F90``.
Subsequently, the Fortran with ISO-C bindings is wrapped in C. This time,
the source code is in ``src/c``. As before, the names of the files are
the same as the corresponding Fortran ones, but ending in ``_iso.c``. Finally,
the C is wrapped in Python in the directory ``src/python``. A low-level
wrapper is made using the same filenames as the Fortran ones but ending in
``.py``. A higher level object-oriented wrapper is contained in
the file ``pyoasis.py``. This higher level wrapper provides the pyOASIS
interface.


Creating a component
++++++++++++++++++++

In pyOASIS, components are instances of the **Component** class. To
initialise a component, its name has to be supplied.::

    import pyoasis
    component_name = "component"
    comp = pyoasis.Component(component_name)

It is also possible to provide an optional ``coupling_flag`` argument which
defaults to coupled.::

    import pyoasis
    component_name = "component"
    coupling_flag = True
    comp = pyoasis.Component(component_name, coupling_flag)


Using MPI
+++++++++

OASIS couples models which communicate using MPI. By default, the
**Component** class will set up MPI internally and provides methods
to get access to information such as rank and number of processes.
In this case, the global communicator used is MPI.COMM_WORLD.::

    import pyoasis
    
    comp = pyoasis.Component("component")
    
    print("Hello world from process " + str(comp.localcomm.rank) 
          + " of " +  str(comp.localcomm.size))


If the user wants to use his or her own communicator, this can be passed 
to the **Component** class through the communicator
optional argument. This should be created with ``mpi4py``. ::

    import pyoasis
    from mpi4py import MPI
    
    comm = MPI.COMM_WORLD

    component_name = "component"
    coupling_flag = True
    comp = pyoasis.Component(component_name, coupling_flag, comm)


Creating a partition
++++++++++++++++++++

The data can be partitioned in various ways.
These correspond to the  **SerialPartition**, **ApplePartition**,
**BoxPartition**, **OrangePartition** and **PointsPartition**
classes which are inherited from the **Partition** abstract class.

The simplest situation is the serial partitioning where all the data is
held by a single process and only the number of points has to be
specified. ::

    n_points = 16
    serial_partition = pyoasis.SerialPartition(n_points)

In the case of the apple partitioning, each process contains a segment
of a linear domain. To initialise such a partitioning, an offset has to
be supplied for each rank as well as the number of data points that
will be stored locally. The following example, if run with 4 processes,
will produce 4 consecutive local segments containing 4 data points. ::

    component_name = "component"
    comp = pyoasis.Component(component_name)
    rank = comp.localcomm.rank
    size = comp.localcomm.size
    n_points = 16
    local_size = int(n_points/size)
    offset = rank * local_size
    partition = pyoasis.ApplePartition(offset, local_size)

When we use the box partitioning, a 2-dimensional domain is split
into several rectangles. The global offset, local extents in the x and
y directions and the global extent in the x direction have to be supplied
to the constructor. The global offset is the index of the corner of the local
rectangle. For example, we can split a 4x4 square domain into 4 2x2 parts with
the following code that will have to be executed using 4 processes. The
offset is computed from the global and local domain sizes as well as
the rank. ::

    rank = comp.localcomm.rank
    n_global_points_per_side = 4
    n_partitions_per_side = 2  
    local_extent = n_global_points_per_side / n_partitions_per_side
    i_partition_x = rank / n_partitions_per_side
    i_partition_y = rank % n_partitions_per_side
    global_offset =   i_partition_x * n_global_points_per_side * local_extent
                    + i_partition_y * local_extent 
    global_extent_x = n_global_points_per_side
    partition = pyoasis.BoxPartition(global_offset, local_extent, local_extent,
                                     global_extent_x)


The orange partitioning consists of several segments of a linear domain.
As a consequence, a list of offsets and local sizes have to be provided.
In this example, each process contains 2 consecutive segments of 2 points. ::

    rank = comp.localcomm.rank 
    n_segments_per_rank = 2
    n_points_per_segment = 2
    offset_beginning = rank * n_segments_per_rank * n_points_per_segment
    offset = [offset_beginning, offset_beginning + n_points_per_segment]
    extents = [n_points_per_segment, n_points_per_segment]
    partition = pyoasis.OrangePartition(offsets, extents)


The last type of partitioning is points, where we have to
specify, in a list, the global indices of the points stored by the
process. ::

    global_indices=[0, 1, 2, 3]
    partition = pyoasis.PointsPartition(global_indices)

See the OASIS documentation for more information about the various
types of partitioning.


Initialising the data
+++++++++++++++++++++

The data is handled by the class **Var**. Its constructor requires
the name, as is appears in the ``namcouple`` file, the partition, the rank
with which we wish to communicate and a flag indicating whether the
data is incoming or outgoing. The latter is an enumerated type and can
have the values ``pyoasis.OasisParameters.OASIS_OUT`` or
``pyoasis.OasisParameters.OASIS_IN``. In the following example, we wish
to send data to a process having the rank 1 and we use a partition that was
previously created.::
    data_name = "name"
    variable = pyoasis.Var(data_name, partition,
                           pyoasis.OasisParameters.OASIS_OUT)

In the case of the receiving model, the code is: ::

    data_name = "name"
    variable = pyoasis.Var(data_name, partition,            
                           pyoasis.OasisParameters.OASIS_IN)

We must end the definition of the component by calling the ``enddef()``
method. ::

    comp.enddef()

However this must be done only once the partitioning and the variable data have been initalised.


Sending and receiving data
++++++++++++++++++++++++++

pyOASIS expects data to be provided as a **pyoasis.asarray** object.
This is a Numpy array but ordered in the Fortran way.
In C, multidimensional arrays store data in row-major order where
contiguous elements are accessed by incrementing the rightmost index
while varying the other indices will correspond to increasing strides in
memory as we use indices further towards the left. By default, Numpy arrays
use that ordering as well. Fortran, on the other hand, uses column-major
order. In that case, contiguous elements are accessed by incrementing
the leftmost index. **pyoasis.asarray** objects use the same ordering as
Fortran. As a consequence, it is not necessary to transform data in order to
use it in the OASIS Fortran library. ::

    field = pyoasis.asarray(range(n_points))

We must also associate a time to the data. If the receiving model
specifies that same time as this model then it receives the data. ::

    date = int(0)

The data is sent with the following function. ::

    variable.put(date, field)

Conversely, it is received with the function ::

    variable.get(date, field)

It expects data carrying the same date and will fill the
**pyoasis.asarray** object.

Finally, the coupling is terminated in the destructor of 
the component.


Exceptions
++++++++++

When an error occurs in OASIS and the code coupler returns an error
code, an **OasisException** is raised and when an
error is caught by the pyOASIS wrapper, such as an incorrect parameter
or a wrong argument type, a **PyOasisException** is raised.

In the following example, where we attempt to initialise a component,
a **PyOasisException** will be raised if the user supplies an empty
name or a component of the wrong type. On the other hand, if a problem
occurs in OASIS, an **OasisException** is raised. ::

    try:
        comp = pyoasis.Component("name")
    except (pyoasis.OasisException, pyoasis.PyOasisException) as exception:
        pyoasis.pyoasis_abort(exception)

A more complete example involving exceptions can be found in
``test/apple_and_orange``, in the files ``receiver-orange.py`` and
``sender-apple.py``. These are used to test pyOASIS with a working
example involving two components communicating and can show how
exceptions might be handled in a real code. There are cases
where OASIS will
abort before pyOASIS can raise an exception. This happens, for instance,
when the name of the variable data is inconsistent with the contents of
the ``namcouple`` file. However, in such a case, one can rely on the error
interception taking place in OASIS which will describe the issue in the log
files.


Examples
--------

Serial partitions
+++++++++++++++++

This example consists in two models, one sending data to
another. The sender and receiver start in the same way.

-Import pyOASIS and initialise the MPI communicator ::

    import pyoasis
    from mpi4py import MPI
    comm = MPI.COMM_WORLD

-Initialisation of the component ::

    comp = pyoasis.Component(component_name)

-Initialisation of the serial partition ::

    partition = pyoasis.SerialPartition(n_points)

-From this point, the sender and the receiver start to
differ. In the sender, the variable data is initialised
by ::

    variable = pyoasis.Var("FSENDOCN", partition, 
                          pyoasis.OasisParameters.OASIS_OUT)

whereas, in the receiver, we have ::

    variable = pyoasis.Var("FRECVATM", partition,
                          pyoasis.OasisParameters.OASIS_IN)
		       
where the last flag is instead ``pyoasis.OasisParameters.OASIS_IN``
to indicate that, in this case, the data will be incoming.

In both scripts, the initialisation of the component ends by ::

    comp.enddef()

In the sender, the data is subsequently transmitted by ::

    time_in_the_model = int(0)
    field = pyoasis.asarray(range(n_points))
    variable.put(time_in_the_model, field)

while, in the receiver, it is recovered by ::

    time_in_the_model = int(0)
    field = pyoasis.asarray(numpy.zeros(n_points))
    variable.get(time_in_the_model, field)

The time in the model must be the same for the two components.

   
The full source code as well as the namcouple file and a script
to run this example are in the directory
``pyoasis/examples/1-serial/python``.


Apple and orange partitions
+++++++++++++++++++++++++++

In this example, both models run as several processes. The beginning
of the code is identical to the previous example. We will highlight
only the differences. In the sender, the data is split according to the apple partitioning ::

    partition = pyoasis.ApplePartition(offset, local_size)

whereas the receiver uses the orange partitioning. ::

    partition = pyoasis.OrangePartition(offsets, extents)

In both cases, the offsets and sizes of the local part of the
data have to be specified. Each process subsequently transmits and
receives its share of the data as previously. In the sender, we have ::

    date = int(0)
    field = pyoasis.asarray(numpy.zeros(local_size))
    for i in range(local_size):
        field[i] = offset + i
    variable.put(date, field)  


while, in the receiver, ::

    date = int(0)
    field = pyoasis.asarray(numpy.zeros(extent))
    variable.get(date, field)

The complete example can be found in ``examples/6-apple_and_orange/python``.


Fortran and Python interoperability
+++++++++++++++++++++++++++++++++++

In order to illustrate the possibility to couple models written in Python and in Fortran, we repeat the previous example where, this time, the sender
has been written in Fortran. The receiver is the same as above.

The sender consists in an analogous sequence.

-Initialisation of the component ::

    call oasis_init_comp(comp_id, comp_name, kinfo)

-Creation of the coupling communicator from the one used by the component ::

    call oasis_get_localcomm(local_comm, kinfo)
    call oasis_create_couplcomm(1, local_comm, coupl_comm, kinfo)

-Initialisation of the apple partition with the relevant offset and
local size ::

    part_params=(/1, offset, local_size/)
    call oasis_def_partition(part_id, part_params, kinfo)

-Creation of the variable data ::

    var_nodims=(/1, 1/)
    var_actual_shape=1
    call oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_OUT,
		      var_actual_shape, OASIS_REAL, kinfo)

-End of the definition of the component ::

   call oasis_enddef(kinfo)

-Transmission of the local part of the data to the other component ::

   call oasis_put(var_id, date, field, kinfo)

-End of the coupling ::

   call oasis_terminate(kinfo)

The complete example can be found in
``pyoasis/examples/7-fortran_and_python``.


API reference
-------------

The class **Component** manages a component that will be coupled
by OASIS. The data can be split in various ways corresponding to the
classes **SerialPartition**, **ApplePartition**, **BoxPartition**,
**OrangePartition** and **PointsPartition** (see the OASIS documentation
for more details). Finally the data is handled by the class **Var**.

.. autoclass:: pyoasis.OasisException

.. autoclass:: pyoasis.PyOasisException

.. autofunction:: pyoasis.pyoasis_abort

.. autoclass:: pyoasis.Component
               :members:
		  
	      
.. autoclass:: pyoasis.SerialPartition

.. autoclass:: pyoasis.ApplePartition

.. autoclass:: pyoasis.BoxPartition
	       
.. autoclass:: pyoasis.OrangePartition

.. autoclass:: pyoasis.PointsPartition

.. autofunction:: pyoasis.OasisParameters()

.. autofunction:: pyoasis.asarray

.. autoclass:: pyoasis.Var
               :members:


Grids are managed by the *Grid* class.
 
.. autoclass:: pyoasis.Grid
               :members:


Correspondence with the OASIS interface
---------------------------------------

These tables show the correspondence between the functions 
described in the OASIS user guide and their analogue in pyOASIS.
All the functions have been implemented with their full interface
except ``put`` which, in the case of pyOASIS, accepts only
a single field. 

All these functions are tested, at the level of 
the Python wrapper, using pytest whereas they are tested, while
running OASIS, by the examples. All these tests cans be executed by 
the command described in section 2.3.


Component
+++++++++

+------------------------------------+-----------------------------------+
| OASIS                              | pyoasis.Component.                |
+====================================+===================================+
| oasis_init_comp(comp_id, comp_name,| __init__(name, coupled=True,      |
| ierror, coupled, comm_world)       |   communicator=MPI.COMM_WORLD)    |
+------------------------------------+-----------------------------------+
| oasis_terminate(ierror)            | __del__()                         |
+------------------------------------+-----------------------------------+
| oasis_create_couplcomm(icpl,       | create_couplcomm(icpl)            |
| localcomm, couplcomm, kinfo)       |                                   |
+------------------------------------+-----------------------------------+
| oasis_set_couplcomm(couplcomm,     | set_couplcomm(couplcomm)          |
| kinfo)                             |                                   |
+------------------------------------+-----------------------------------+
| oasis_get_intracomm(newcomm, cdnam,| get_intracomm(compname)           | 
| kinfo)                             |                                   |
+------------------------------------+-----------------------------------+
| oasis_get_intercomm(newcomm,       | get_intercomm(compname)           |
| cdnam, kinfo)                      |                                   |
+------------------------------------+-----------------------------------+
| oasis_enddef(ierror)               | enddef()                          |
+------------------------------------+-----------------------------------+
| oasis_get_local_comm(local_comm,   | localcomm                         |
| ierror)                           |                                    |
+------------------------------------+-----------------------------------+
| oasis_get_debug(debugvalue)        | debug_level                       |
+------------------------------------+-----------------------------------+
| oasis_set_debug(debugvalue)        | debug_level                       |
+------------------------------------+-----------------------------------+

Partition
+++++++++

+------------------------------------+-----------------------------------+
| OASIS                              | pyoasis.                          |
+====================================+===================================+
| oasis_def_partition(ilpart_id,     | SerialPartition(size,             |
|   igparal, ierror, isize, name)    |   global_size=-1, name="")        |
|                                    | ApplePartition(offset, size,      |
|                                    |   global_size=-1, name="")        |
|                                    | BoxPartition(global_offset,       |
|                                    |   local_extent_x, local_extent_y, |
|                                    |   global_extent_x, global_size=-1,|
|                                    |   name="")                        |
|                                    | OrangePartition(offsets, extents, |
|                                    |   global_size=-1, name="")        | 
|                                    | PointsPartition(global_indices,   |
|                                    |   global_size=-1, name="")        |
+------------------------------------+-----------------------------------+

Var
+++

+------------------------------------+-----------------------------------+
| OASIS                              | pyoasis.var.                      |
+====================================+===================================+
| oasis_def_var(var_id, name,        | __init__(name, partition, inout,  | 
|   il_part_id, var_nodims, kinout,  |   bundle_size=1)                  |
|   var_actual_shape, vartype,       |                                   |
|   ierror)                          |                                   |
+------------------------------------+-----------------------------------+
| oasis_put(varid, date, fld1, info, | put(time, field,                  |
| fld2, fld3, fld4, fld5,            |   write_restart=False)            |
| write_restart)                     |                                   |
+------------------------------------+-----------------------------------+
| oasis_get(varid, date, fld, info)  | get(time, field)                  |
+------------------------------------+-----------------------------------+
| oasis_put_inquire(varid, date,     | put_inquire(time)                 |
|   kinfo)                           |                                   |
+------------------------------------+-----------------------------------+
| oasis_get_ncpl(varid, ncpl, kinfo) | len(cpl_freqs)                    |
+------------------------------------+-----------------------------------+
| oasis_get_freqs(varid, mop, ncpl,  | cpl_freqs                         |
|   cplfreqs, kinfo)                 |                                   |
+------------------------------------+-----------------------------------+

Grid
++++

+---------------------------------+------------------------------+
| OASIS                           | pyoasis.grid.                |
+=================================+==============================+
| oasis_start_grids_writing(flag) | __init__(cgrid, nx_global,   |
| oasis_write_grid(cgrid,         |   ny_global, lon, lat,       |
|   nx_global, ny_global, lon,    |   partition=None)            |
|   lat, il_partid)               |                              |
+---------------------------------+------------------------------+
| oasis_write_corner(cgrid,       | set_corners(clo, cla)        |
|   nx_global, ny_global, nc,     |                              |
|   clon, clat, il_partid)        |                              |
+---------------------------------+------------------------------+
| oasis_write_area(cgrid,         | set_area(area)               |
|   nx_global, ny_global,         |                              |
|   area, il_partid)              |                              |
+---------------------------------+------------------------------+
| oasis_write_mask(cgrid,         | set_mask(mask,               | 
|   nx_glo, ny_glo, mask,         |   companion=None)            |
|   part_id, companion)           |                              |
+---------------------------------+------------------------------+
| oasis_write_frac(cgrid,         | set_frac(frac,               |
|   nx_glo, ny_glo, frac,         |   companion=None)            |
|   part_id, companion)           |                              |
+---------------------------------+------------------------------+
| oasis_terminate_grids_writing() | write()                      |
+---------------------------------+------------------------------+

Utilities
+++++++++

+---------------------------------+-------------------------------+
| OASIS                           | pyoasis.                      | 
+=================================+===============================+
|oasis_abort(compid, routinename, | oasis_abort(component_id,     |
|  abortmessage, rcode)           |   routine, message, filename, |
|                                 |   line, error)                |
|                                 | pyoasis_abort(exception)      |
+---------------------------------+-------------------------------+


Acknowledgments
---------------

This work has been financed by the ISENES3 project which has received funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement No 824084.

.. image:: euflag.png
	   
Index and search
----------------

* :ref:`genindex`
* :ref:`search`
