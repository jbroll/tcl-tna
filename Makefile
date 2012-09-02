
tna:	tna.tcl tna.h
	critcl3.kit -force -pkg tna 

tna.tcl : tna.critcl tna-tcl.tcl expression.tcl functional.tcl tcloo.tcl
	unsource tna.critcl > tna.tcl

test: tna FORCE
	./tna-test.tcl

clean:
	rm tna.tcl

timing:
	cd comparison; ./compare


# Install ActiveState python
#    pypm install numpy
#    pypm install numexpr
#
python:
	time /usr/local/bin/python2.7   numpy-test.py
	time /usr/local/bin/python2.7 numexpr-test.py

FORCE:
