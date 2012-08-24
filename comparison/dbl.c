

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define NX 2048

main() {
    	int i, x, y;
	double *a;
	double *b;
	volatile double *data;

    a    = (double *) calloc(NX*NX,sizeof(double));
    b    = (double *) calloc(NX*NX,sizeof(double));
    data = (double *) calloc(NX*NX,sizeof(double));

    for ( i = 0; i < 100; i++ ) {
	for ( y = 0; y < NX; y++ ) {
	    for ( x = 0; x < NX; x++ ) {

		data[y*NX+x] = pow(a[y*NX+x], 2) + pow(b[y*NX+x], 2) + 2 * a[y*NX+x] *b[y*NX+x];
	    }
	}
    }
}
