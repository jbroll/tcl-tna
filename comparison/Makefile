
all : flt dbl dbl-omp test

dbl: dbl.c
	gcc -O3 dbl.c -o dbl

dbl-omp: dbl-omp.c
	gcc -fopenmp -O3 dbl-omp.c -o dbl-omp

flt: flt.c
	gcc -O3 flt.c -o flt

test:
	-time dbl
	-time dbl-omp
	-time flt
	-time python2.7 numexpr-test.py
	-time python2.7 numpy-test.py
