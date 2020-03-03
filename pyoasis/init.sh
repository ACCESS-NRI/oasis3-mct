OPT=${HOME}/opt
OASIS=${HOME}/oasis3-mct/
PYOASIS=${OASIS}/pyoasis
MODULES=${PYOASIS}/oasis/modules

export C_INCLUDE_PATH=${PYOASIS}:${OPT}/include:/usr/local/lib:${C_INCLUDE_PATH}
export CPLUS_INCLUDE_PATH=${OPT}/include:${CPLUS_INCLUDE_PATH}
export LD_LIBRARY_PATH=${PYOASIS}:${OPT}/lib:${LD_LIBRARY_PATH}
export PYTHONPATH=${OPT}/modules:${PYTHONPATH}
export PATH=${OPT}/bin:${PATH}
