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
	cd $(PYOASIS)/examples/1-serial/python && (bash run.sh | tee test_output.txt) && grep -iq "successfully" test_output.txt && rm -f test_output.txt

example2:
	cd $(PYOASIS)/examples/2-apple/python && (bash run.sh | tee test_output.txt) && grep -iq "successfully" test_output.txt && rm -f test_output.txt

example3:
	cd $(PYOASIS)/examples/3-box/python && (bash run.sh | tee test_output.txt) && grep -iq "successfully" test_output.txt && rm -f test_output.txt

example4:
	cd $(PYOASIS)/examples/4-orange/python && (bash run.sh | tee test_output.txt) && grep -iq "successfully" test_output.txt && rm -f test_output.txt

example5:
	cd $(PYOASIS)/examples/5-points/python && (bash run.sh | tee test_output.txt) && grep -iq "successfully" test_output.txt && rm -f test_output.txt

example6:
	cd $(PYOASIS)/examples/6-apple_and_orange/python && (bash run.sh | tee test_output.txt) && grep -iq "successfully" test_output.txt && rm -f test_output.txt

example7:
	cd $(PYOASIS)/examples/7-multiple-puts/python && (bash run.sh | tee test_output.txt) && grep -iq "field 2 received successfully at time 40800" test_output.txt && rm -f test_output.txt

example8:
	cd $(PYOASIS)/examples/8-fortran_and_python && make clean && (bash run.sh | tee test_output.txt) && grep -iq "successfully" test_output.txt && rm -f test_output.txt

example9:
	cd $(PYOASIS)/examples/9-python_fortran_C-multi_intracomm  && make clean && (bash run.sh | tee test_output.txt) && grep -iq "successfully" test_output.txt && rm -f test_output.txt

example10:
	cd $(PYOASIS)/examples/10-grid/python && (bash run.sh | tee test_output.txt) && grep -iq "successfully" test_output.txt && rm -f test_output.txt
