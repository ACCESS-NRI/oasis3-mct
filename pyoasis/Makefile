PYOASIS=$(COUPLE)/pyoasis

# Test

ifeq ($(PYOASIS),/pyoasis)
PYOASIS := .
endif

test: wrappertest completetest

wrappertest: wrappertest
	cd $(PYOASIS)/tests && pytest

completetest: 
	cd $(PYOASIS)/tests/apple_and_orange/ && bash run.sh
