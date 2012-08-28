

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define NX 2048

typedef double v2dd __attribute__ ((vector_size(16)));

main() {
    	int i, x, y;

	v2dd *ax, *bx, *cx;
	v2dd two;

	((double *)&two)[0] = 2.0;
	((double *)&two)[1] = 2.0;

	double *a;
	double *b;
	volatile double *c;

    a = (double *) calloc(NX*NX,sizeof(double));
    b = (double *) calloc(NX*NX,sizeof(double));
    c = (double *) calloc(NX*NX,sizeof(double));

    for ( y = 0; y < NX; y++ ) {
	for ( x = 0; x < NX; x++ ) {
	    a[y*NX+x] = 1;
	    b[y*NX+x] = 4;
	}
    }

    ax = (v2dd *) a;
    bx = (v2dd *) b;
    cx = (v2dd *) c;

    for ( i = 0; i < 100; i++ ) {
	for ( y = 0; y < NX; y++ ) {
	    for ( x = 0; x < NX/2; x++ ) {
		cx[y*NX/2+x] =  ax[y*NX/2+x]*ax[y*NX/2+x]
		    + bx[y*NX/2+x]*bx[y*NX/2+x]
		    + two * ax[y*NX/2+x]*bx[y*NX/2+x];
	    }
	}
    }

    printf("%f\n", c[0]);
}
