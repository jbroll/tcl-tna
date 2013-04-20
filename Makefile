
tna32	= lib/tna/macosx-ix86/tna.dylib
tna64	= lib/tna/macosx-x86_64/tna.dylib

nproc32	= lib/nproc/macosx-ix86/nproc.dylib
nproc64	= lib/nproc/macosx-x86_64/nproc.dylib

x32: $(tna32) $(nproc32)

all: arec $(tna32) $(tna64) $(nproc32) $(nproc64)

TNASOURCE = tna.h tna-register.h tna-register.tcl tna-register.unsourced	\
	    tna.tcl tna-util.tcl tna-parse.tcl tna-disassemble.tcl		\
	    tna-array.tcl expression.tcl functional.tcl tcloo.tcl


$(tna32): $(TNASOURCE)
	critcl -target macosx-x86_32 -force -pkg tna 
	rm -rf lib/tna/macosx-ix86
	mv lib/tna/macosx-x86_32 lib/tna/macosx-ix86
	rm -f tna-register.unsourced

$(tna64): $(TNASOURCE)
	critcl -target macosx-x86_64 -force -pkg tna 

$(nproc32): nproc.tcl
	critcl -target macosx-x86_32 -force -pkg nproc 
	rm -rf lib/nproc/macosx-ix86
	mv lib/nproc/macosx-x86_32 lib/nproc/macosx-ix86

$(nproc64): nproc.tcl
	critcl -target macosx-x86_64 -force -pkg nproc 
	rm -f tna-register.unsourced

tna-register.unsourced : tna-register.tcl
	unsource tna-register.tcl > tna-register.unsourced

test: FORCE
	cd arec; $(MAKE) test
	arch -i386   /usr/local/bin/tclsh8.6 ./tna-test.tcl 
	arch -x86_64 /usr/local/bin/tclsh8.6 ./tna-test.tcl

clean:
	rm -f tna.tcl

timing:
	cd comparison; ./compare

time:
	cd comparison; time ./tna-time.tcl


arec : FORCE
	cd arec; $(MAKE)

arec-test : FORCE
	./tna-test.tcl -file 'arec.*'



# Install ActiveState python
#    pypm install numpy
#    pypm install numexpr
#
python:
	time /usr/local/bin/python2.7   numpy-test.py
	time /usr/local/bin/python2.7 numexpr-test.py

FORCE:
