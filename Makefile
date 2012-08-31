
tna:	tna.tcl
	critcl3.kit -force -pkg tna 

tna.tcl : tna.critcl
	unsource tna.critcl > tna.tcl

test: FORCE
	./tna-test

clean:
	rm tna.tcl

timing:
	./timing


# Install ActiveState python
#    pypm install numpy
#    pypm install numexpr
#
python:
	time /usr/local/bin/python2.7   numpy-test.py
	time /usr/local/bin/python2.7 numexpr-test.py

FORCE:
