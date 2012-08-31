
all : flt dbl dbl-mmx dbl-omp 

dbl: dbl.c
	gcc -O3 dbl.c -o dbl

dbl-mmx: dbl-mmx.c
	gcc -O3 dbl-mmx.c -o dbl-mmx

dbl-omp: dbl-omp.c
	gcc -fopenmp -O3 dbl-omp.c -o dbl-omp

flt: flt.c
	gcc -O3 flt.c -o flt

