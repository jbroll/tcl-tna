

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define NX 2048

main() {
    	int i, x, y;
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

    for ( i = 0; i < 100; i++ ) {
	for ( y = 0; y < NX; y++ ) {
	    for ( x = 0; x < NX; x++ ) {
		c[y*NX+x] = a[y*NX+x]*a[y*NX+x] + b[y*NX+x]*2 + 2 * a[y*NX+x] *b[y*NX+x];
	    }
	}
    }

    printf("%f\n", c[0]);
}
