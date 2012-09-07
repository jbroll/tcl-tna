
TCL_LIBS=/home/john/lib 

test : test.c tpool.o tpool.h
	$(CC) -DTCL_THREADS=1 -I./tcl/generic -g -o test test.c tpool.o -L$(TCL_LIBS) -ltcl8.6

tpool.o : tpool.c tpool.h
	$(CC) -DTCL_THREADS=1 -I./tcl/generic -c -o tpool.o tpool.c

clean:
	rm -f *.o
	rm -f test

