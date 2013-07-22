
OS  =$(shell uname)
ARCH=$(OS).$(shell uname -m)

all: tna.$(OS) arec.$(OS) nproc.$(OS)

TNASOURCE = tna.h register.h register.tcl register.unsourced	\
	    tna.tcl init.tcl parse.tcl disassemble.tcl		\
	    array.tcl expression.tcl 				\
	    arec/jbr.tcl/func.tcl arec/jbr.tcl/tcloo.tcl	\
	    api.tcl


tna.Darwin : arec.Darwin.i386 arec.Darwin.x86_64 tna.Darwin.i386 tna.Darwin.x86_64 test.Darwin
tna.Linux  :                  arec.Linux.x86_64                  tna.Linux.x86_64  test.Linux


arec.Darwin.i386	:
	cd arec; $(MAKE) arec.Darwin.i386

arec.Darwin.x86_64	:
	cd arec; $(MAKE) arec.Darwin.x86_64

arec.Linux.x86_64 	:
	cd arec; $(MAKE) arec.Linux.x86_64


tna.Darwin : tna.Darwin.i386 tna.Darwin.x86_64

tna.Darwin.i386	  : lib/tna/macosx-ix86/tna.dylib
tna.Darwin.x86_64 : lib/tna/macosx-x86_64/tna.dylib

lib/tna/macosx-ix86/tna.dylib   : $(TNASOURCE) opcodes32.o
	critcl -target macosx-x86_32 -pkg tna 
	#rm -rf lib/tna/macosx-ix86
	#mv lib/tna/macosx-x86_32 lib/tna/macosx-ix86
	rm opcodes.o

lib/tna/macosx-x86_64/tna.dylib : $(TNASOURCE) opcodes64.o
	critcl -target macosx-x86_64 -pkg tna 
	rm opcodes.o

nproc.Darwin : nproc.Darwin.i386 nproc.Darwin.x86_64

nproc.Darwin.i386	: lib/nproc/macosx-ix86/nproc.dylib
nproc.Darwin.x86_64	: lib/nproc/macosx-x86_64/nproc.dylib

lib/nproc/macosx-ix86/nproc.dylib   : nproc.tcl
	critcl -target macosx-x86_32 -force -pkg nproc 
	#rm -rf lib/nproc/macosx-ix86
	#mv lib/nproc/macosx-x86_32 lib/nproc/macosx-ix86

lib/nproc/macosx-x86_64/nproc.dylib : nproc.tcl
	critcl -target macosx-x86_64 -force -pkg nproc 
	

register.unsourced : register.tcl register.h
	unsource register.tcl > register.unsourced

test.Darwin: FORCE
	cd arec; $(MAKE) test
	arch -i386   /usr/local/bin/tclsh8.6 ./tna-test.tcl 
	arch -x86_64 /usr/local/bin/tclsh8.6 ./tna-test.tcl

clean:

timing:
	cd comparison; ./compare

time:
	cd comparison; time ./tna-time.tcl


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

tna-ext.h : mkdefs.tcl
	tclsh mkdefs.tcl > tna-ext.h



# Install ActiveState python
#    pypm install numpy
#    pypm install numexpr
#
python:
	time /usr/local/bin/python2.7   numpy-test.py
	time /usr/local/bin/python2.7 numexpr-test.py

FORCE:
