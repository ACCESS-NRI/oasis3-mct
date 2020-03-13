pyOASIS Documentation
=====================

.. toctree::   
   :maxdepth: 2
   :caption: Contents:



Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`


Installation
============
pyOASIS is a Python wrapper for the code coupler OASIS written using ctypes and ISO C bindings to Fortran.

It is part of the distribution of OASIS *[currently only in the dev-pyoasis branch]*. See the documentation of OASIS at http://www.cerfacs.fr/oa4web/oasis3-mct_4.0/oasis3mct_UserGuide.pdf for instructions about how to obtain the software.

Once OASIS has been installed, pyOASIS can be compiled and installed by the following procedure from the ``oasis3-mct`` directory. By default, pyOASIS wil be installed in ``${HOME}/opt``.
::
    cd pyoasis
    source init.sh
    make
    make install

The command line ``source init.sh`` initialises some environment variables necessary for the compilation and execution of pyOASIS. As a consequence, it should also be called before using pyOASIS.


API
===

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
	    
Array
-----
Wraps a numpy array of double-precision floating numbers. Multidimensional arrays are ordered in the same way as in Fortran.  

Component
---------




		     
Examples
========

Acknowledgments
===============

