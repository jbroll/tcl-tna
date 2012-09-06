
TCL_LIBS=/home/john/lib 

test : test.c tpool.o tpool.h
	$(CC) -g -o test test.c tpool.o -L$(TCL_LIBS) -ltcl8.6

tpool.o : tpool.c tpool.h
	$(CC) -c -o tpool.o tpool.c

clean:
	rm -f *.o
	rm -f test

