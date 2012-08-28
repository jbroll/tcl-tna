
tna:
	critcl3.kit -force -pkg tna 

test: FORCE
	@for test in test/*; do cd test; `basename $$test`; done


# Install ActiveState python
#    pypm install numpy
#    pypm install numexpr
#
python:
	time /usr/local/bin/python2.7   numpy-test.py
	time /usr/local/bin/python2.7 numexpr-test.py

FORCE:
