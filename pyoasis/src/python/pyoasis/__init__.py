from pyoasis.exception import OasisException
from pyoasis.exception import PyOasisException
from pyoasis.parameters import *
from pyoasis.asarray import *
from pyoasis.checktypes import *
from pyoasis.abort import *
from pyoasis.component import *
from pyoasis.terminate import *
from pyoasis.partition import *
from pyoasis.var import *
import sys


# Global error handler
def global_except_hook(exctype, value, traceback):
    """
    Shut down a whole MPI application if one of the processes fails
    """
    import sys
    try:
        import mpi4py.MPI
        sys.stderr.write("\n*****************************************************\n" +
                         "Uncaught exception was detected on rank {}. \n".format(
                             mpi4py.MPI.COMM_WORLD.Get_rank()))
        from traceback import print_exception
        print_exception(exctype, value, traceback)
        sys.stderr.flush()
    finally:
        try:
            import mpi4py.MPI
            mpi4py.MPI.COMM_WORLD.Abort(1)
        except Exception as e:
            sys.stderr.write("*****************************************************\n")
            sys.stderr.write("Sorry, we failed to stop MPI, this process will hang.\n")
            sys.stderr.write("*****************************************************\n")
            sys.stderr.flush()
            raise e


sys.excepthook = global_except_hook
