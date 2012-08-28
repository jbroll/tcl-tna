

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define NX 2048

typedef float v2df __attribute__ ((vector_size(16)));

main() {
    	int i, x, y;

	v2df *ax, *bx, *cx;
	v2df two;

	((float *)&two)[0] = 2.0;
	((float *)&two)[1] = 2.0;

	float *a;
	float *b;
	volatile float *c;

    a = (float *) calloc(NX*NX,sizeof(float));
    b = (float *) calloc(NX*NX,sizeof(float));
    c = (float *) calloc(NX*NX,sizeof(float));

    for ( y = 0; y < NX; y++ ) {
	for ( x = 0; x < NX; x++ ) {
	    a[y*NX+x] = 1;
	    b[y*NX+x] = 4;
	}
    }

    ax = (v2df *) a;
    bx = (v2df *) b;
    cx = (v2df *) c;

    for ( i = 0; i < 100; i++ ) {
	for ( y = 0; y < NX; y++ ) {
	    for ( x = 0; x < NX/4; x++ ) {
		cx[y*NX/4+x] =  ax[y*NX/4+x]*ax[y*NX/4+x]
		    + bx[y*NX/4+x]*bx[y*NX/4+x]
		    + two * ax[y*NX/4+x]*bx[y*NX/4+x];
	    }
	}
    }

    printf("%f\n", c[0]);
}
