PYOASIS=$(COUPLE)/pyoasis


# Doc
doc:
	cd docs && make latexpdf && cp _build/latex/pyoasis.pdf ..

# Test

ifeq ($(PYOASIS),/pyoasis)
PYOASIS := .
endif

test: wrappertest completetest examples

wrappertest: wrappertest
	cd $(PYOASIS)/tests && ./run_pytest.sh

completetest: 
	cd $(PYOASIS)/tests/apple_and_orange && bash run.sh

examples: example1 example2 example3 example4 example5 example6 example8 example7 example9 example10

example1:
	cd $(PYOASIS)/examples/1-serial/python && bash run.sh

example2:
	cd $(PYOASIS)/examples/2-apple/python && bash run.sh

example3:
	cd $(PYOASIS)/examples/3-box/python && bash run.sh

example4:
	cd $(PYOASIS)/examples/4-orange/python && bash run.sh

example5:
	cd $(PYOASIS)/examples/5-points/python && bash run.sh

example6:
	cd $(PYOASIS)/examples/6-apple_and_orange/python && bash run.sh

example7:
	cd $(PYOASIS)/examples/7-multiple-puts/python && bash run.sh

example8:
	cd $(PYOASIS)/examples/8-fortran_and_python && make clean && bash run.sh

example9:
	cd $(PYOASIS)/examples/9-python_fortran_C-multi_intracomm  && make clean && bash run.sh

example10:
	cd $(PYOASIS)/examples/10-grid/python && bash run.sh
