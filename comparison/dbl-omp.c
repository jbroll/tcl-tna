

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define NX 2048

main() {
    	int i, x, y;
	double a;
	double b;
	volatile double *data;

    data = (double *) malloc(NX*NX*sizeof(double));

    for ( i = 0; i < 100; i++ ) {
    #pragma omp parallel for
	for ( y = 0; y < NX; y++ ) {
	    for ( x = 0; x < NX; x++ ) {
		a = x+y;
		b = 2;

		data[y*NX+x] = pow(a, 2) + pow(b, 2) + 2 * a *b;
	    }
	}
    }
}
