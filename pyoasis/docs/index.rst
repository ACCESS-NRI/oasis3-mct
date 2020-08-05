pyOASIS Documentation
=====================

.. toctree::
   :maxdepth: 2
   :caption: Contents:


Introduction
------------

pyOASIS is a Python wrapper for OASIS written using ctypes
and ISO C bindings to Fortran. It provides an object-oriented
interface to OASIS. This allows users to write models in Python
or to couple a model written in Python to another one, written
in Fortran.

It is part of the distribution of OASIS. See
http://www.cerfacs.fr/oa4web/oasis3-mct_4.0/oasis3mct_UserGuide.pdf
for more information about obtaining it.

pyOASIS is distributed under the GNU Lesser General Public
License. For more details, see the file lgpl-3.0.txt or
https://www.gnu.org/licenses/lgpl-3.0.en.html.

Installation
------------

Once the installation of OASIS is complete, pyOASIS can be installed
by carrying out the following procedure from the ``oasis3-mct``
directory.
::
    cd pyoasis
    make
    make install
 
By default, this will install pyOASIS in ``${HOME}/opt``. It is
possible to install it in another location by replacing the last
line by
::
     make PREFIX=other_location install

Before using pyOASIS, certain environment variables have to be modified.
This can be done by executing the relevant script (which was created
during the installation according to the location where the software
has been placed) with the command
::
    source init.sh

Alternatively, its contents, which are also displayed at the end of the
installation, should be copied to your ~/.bashrc file.


API reference
-------------

The class **Component** manages a component that will be coupled
by OASIS. The data can be split in various ways corresponding to the
classes **SerialPartition**, **ApplePartition**, **BoxPartition**,
**OrangePartition** and **PointsPartition** (see the OASIS documentation
for more details). Finally the data is handled by the class **Var**.

.. autoclass:: pyoasis.Component
               :members:

.. autofunction:: pyoasis.terminate
	      
.. autoclass:: pyoasis.SerialPartition

.. autoclass:: pyoasis.ApplePartition

.. autoclass:: pyoasis.BoxPartition
	       
.. autoclass:: pyoasis.OrangePartition

.. autoclass:: pyoasis.PointsPartition

.. autofunction:: pyoasis.OasisParameters

.. autofunction:: pyoasis.Array

.. autoclass:: pyoasis.Var
               :members:


Examples
--------

Serial partitions
+++++++++++++++++

This example consists in two models, one sending data to
another. The sender and receiver start in the same way.

-Import pyOASIS and initialise the MPI communicator
::
    import pyoasis
    from mpi4py import MPI
    comm = MPI.COMM_WORLD

-Initialisation of the component  
::
    comp = pyoasis.Component(component_name)

-Creation of the communicator used for the coupling
::
    coupl_comm = comp.create_couplcomm(1)

-Initialisation of the serial partition
::
    partition = pyoasis.SerialPartition(n_points)

-From this point, the sender and the receiver start to
differ. In the sender, the variable data is initialised
by
::
    variable = pyoasis.Var("FSENDOCN", partition.get_id(), [1, 1],
                          pyoasis.OasisParameters.OASIS_OUT.value)

whereas, in the receiver, we have
::
    variable = pyoasis.Var("FRECVATM", partition.get_id(), [1, 1,],
                          pyoasis.OasisParameters.OASIS_IN.value)
		       
where the last flag is instead ``pyoasis.OasisParameters.OASIS_IN.value``
to indicate that, in this case, the data will be incoming.

In both scripts, the initialisation of the component ends by
::
    comp.enddef()

In the sender, the data is subsequently transmitted by
::
    time_in_the_model = int(0)
    field = pyoasis.Array(range(n_points))
    variable.put(time_in_the_model, field)

while, in the receiver, it is recovered by
::
    time_in_the_model = int(0)
    field = pyoasis.Array(numpy.zeros(n_points))
    variable.get(time_in_the_model, field)

The time in the model must be the same for the two components.

Finally the coupling ends with
::
   pyoasis.terminate()
   
The full source code as well as the namcouple file and a script
to run this example are in the directory
``pyoasis/examples/1-serial/python``.


Apple and orange partitions
+++++++++++++++++++++++++++

In this example, both models run as several processes. In the
sender, the data is split according to the apple partitioning
::
    partition = pyoasis.ApplePartition(offset, local_size)

whereas the receiver uses the orange partitioning.
::
    partition = pyoasis.OrangePartition(offsets, extents)

In both cases, the offsets and sizes of the local part of the
data have to be specified. Each process subsequently transmits and
receives its share of the data as previously. In the sender, we have
::
   date = int(0)
   field = pyoasis.Array(numpy.zeros(local_size))
   for i in range(local_size):
      field[i] = offset + i
   variable.put(date, field)  

while , in the receiver, 
::
   date = int(0)
   field = pyoasis.Array(numpy.zeros(extent))
   variable.get(date, field)

The complete example can be found in ``examples/6-apple_and_orange/python``.


Fortran and Python interoperability
+++++++++++++++++++++++++++++++++++

In order to illustrate the possibility to couple models written in Python and
in Fortran, we repeat the previous example where, this time, the sender
has been written in Fortran.

The sender consists in an analogous sequence.

-Initialisation of the component
::
   call oasis_init_comp(comp_id, comp_name, kinfo)

-Creation of the coupling communicator from the one used by the component
::
   call oasis_get_localcomm(local_comm, kinfo)
   call oasis_create_couplcomm(1, local_comm, coupl_comm, kinfo)

-Initialisation of the apple partition with the relevant offset and
local size
::
   part_params=(/1, offset, local_size/)
   call oasis_def_partition(part_id, part_params, kinfo)

-Creation of the variable data
::
   var_nodims=(/1, 1/)
   var_actual_shape=1
   call oasis_def_var(var_id, var_name, part_id, var_nodims, OASIS_OUT,
		      var_actual_shape, OASIS_REAL, kinfo)

-End of the definition of the component
::
   call oasis_enddef(kinfo)

-Transmission of the local part of the data to the other component
::
   call oasis_put(var_id, date, field, kinfo)

-End of the coupling
::
   call oasis_terminate(kinfo)

The complete example can be found in
``pyoasis/examples/7-fortran_and_python``.


   
Acknowledgments
---------------

This project has received funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement No 824084.

.. image:: euflag.png
	   
Index and search
----------------

* :ref:`genindex`
* :ref:`search`
