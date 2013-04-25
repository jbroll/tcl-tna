
tna32	= lib/tna/macosx-ix86/tna.dylib
tna64	= lib/tna/macosx-x86_64/tna.dylib

nproc32	= lib/nproc/macosx-ix86/nproc.dylib
nproc64	= lib/nproc/macosx-x86_64/nproc.dylib

all: arec $(tna32) $(tna64) $(nproc32) $(nproc64)

tna32:    $(tna32)          $(nproc32)			arec32
tna64:    $(tna64)          $(nproc64)			arec64



TNASOURCE = tna.h register.h register.tcl register.unsourced	\
	    tna.tcl init.tcl parse.tcl disassemble.tcl		\
	    array.tcl expression.tcl functional.tcl tcloo.tcl

$(tna32): $(TNASOURCE) opcodes32.o
	critcl -target macosx-x86_32 -pkg tna 
	rm -rf lib/tna/macosx-ix86
	mv lib/tna/macosx-x86_32 lib/tna/macosx-ix86
	rm opcodes.o

$(tna64): $(TNASOURCE) opcodes64.o
	critcl -target macosx-x86_64 -pkg tna 
	rm opcodes.o

$(nproc32): nproc.tcl
	critcl -target macosx-x86_32 -force -pkg nproc 
	rm -rf lib/nproc/macosx-ix86
	mv lib/nproc/macosx-x86_32 lib/nproc/macosx-ix86

$(nproc64): nproc.tcl
	critcl -target macosx-x86_64 -force -pkg nproc 

register.unsourced : register.tcl register.h
	unsource register.tcl > register.unsourced

test: FORCE
	cd arec; $(MAKE) test
	arch -i386   /usr/local/bin/tclsh8.6 ./tna-test.tcl 
	arch -x86_64 /usr/local/bin/tclsh8.6 ./tna-test.tcl

clean:

timing:
	cd comparison; ./compare

time:
	cd comparison; time ./tna-time.tcl


arec : arec32 arec64

arec32: FORCE
	cd arec; $(MAKE) arec32

arec64: FORCE
	cd arec; $(MAKE) arec64
	

arec-test : FORCE
	./tna-test.tcl -file 'arec.*'

opcodes32.o : opcodes.o opcodes.c
	$(CC) -c -O3 -m32 opcodes.c -o opcodes32.o
	rm -f opcodes.o
	ln -s opcodes32.o opcodes.o

opcodes64.o : opcodes.o opcodes.c
	$(CC) -c -O3      opcodes.c -o opcodes64.o
	rm -f opcodes.o
	ln -s opcodes64.o opcodes.o

opcodes.o : opcodes.c
	true

opcodes.c : opcodes.tcl
	tclkit8.6 opcodes.tcl > opcodes.c



# Install ActiveState python
#    pypm install numpy
#    pypm install numexpr
#
python:
	time /usr/local/bin/python2.7   numpy-test.py
	time /usr/local/bin/python2.7 numexpr-test.py

FORCE:
