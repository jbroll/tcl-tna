

tna:	tna.h tna.critcl tna-tcl.tcl expression.tcl functional.tcl tcloo.tcl
	unsource tna.critcl > tna.tcl
	critcl3.kit -force -pkg tna 
	rm tna.tcl


test: FORCE
	./tna-test.tcl

clean:
	rm tna.tcl

timing:
	cd comparison; ./compare

time:
	cd comparison; time ./tna-time.tcl


# Install ActiveState python
#    pypm install numpy
#    pypm install numexpr
#
python:
	time /usr/local/bin/python2.7   numpy-test.py
	time /usr/local/bin/python2.7 numexpr-test.py

FORCE:
