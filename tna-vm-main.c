
#define I(op, type)	INSTR_##op##_##type
#define xType double

// Pass in a slice with slice_run indicies to enable threading
// define "machine" struct.
// Copy machine function to enable threading.
// allocate D and link to Dims registers at slice_run() startup.
//
main() {
	xType one = 1;
	xType two = 2;
	int i;

    	int D[NDIM];
	Register *R = (Register *)malloc(sizeof(Register) * 15);


#define RX  0
#define RY  1
#define RZ  2
#define RU  3
#define RV  4

#define RA  5
#define RB  6
#define RC  7

#define T1  8
#define T2  9
#define T3 10
#define T4 11
#define T5 12
#define T6 13
#define T7 14


#define NX 1024

//	a = X+Y
//	b = 2
//	a**2 + b**2 + 2*a*b


			/*    dims, star, incr, size, step */
	Slice A = { NULL, { {   NX,    0,    1,   NX,    1,   sizeof(xType) }
	    	          , {   NX,    0,    1,   NX,   NX,   sizeof(xType) } } };
	Slice B = { NULL, { {   NX,    0,    1,   NX,    1,   sizeof(xType) }
	    		  , {   NX,    0,    1,   NX,   NX,   sizeof(xType) } } };
	Slice C = { NULL, { {   NX,    0,    1,   NX,    1,   sizeof(xType) }
	    		  , {   NX,    0,    1,   NX,   NX,   sizeof(xType) } } };

	A.data = malloc(sizeof(xType) * NX*NX);
	B.data = malloc(sizeof(xType) * NX*NX);
	C.data = malloc(sizeof(xType) * NX*NX);

	R[RA].slice = A;
	R[RA].offs[2] = A.data;
	R[RB].slice = B;
	R[RB].offs[2] = B.data;
	R[RC].slice = C;
	R[RC].offs[2] = C.data;


	slice_val(&R[T1], &one);
	slice_val(&R[T2], &two);

	slice_reg(&R[T3], sizeof(int));
	slice_reg(&R[T4], sizeof(xType));
	slice_reg(&R[T5], sizeof(xType));
	slice_reg(&R[T6], sizeof(xType));
	slice_reg(&R[T7], sizeof(xType));

	slice_val(&R[RX], &D[0]);
	slice_val(&R[RY], &D[1]);
	slice_val(&R[RZ], &D[2]);
	slice_val(&R[RU], &D[3]);
	slice_val(&R[RV], &D[4]);

	Instr p[] = {
	      { I(double, double), T1,  0, RA }		// A as double
	    , { I(double, double), T2,  0, RB }		// A as double

	    , { I(mul   , double), RA, T4, T5 }		// 2*A  -> T5
	    , { I(mul   , double), T5, RB, T5 }		// T5*B -> T5

	    , { I(mul   , double), RA, RA, T7 }		// A**2 -> T3
	    , { I(mul   , double), RB, RB, T4 }		// B**2 -> T4

	    , { I(add   , double), T7, T5, T5 }		// T3+T5-> T5
	    , { I(add   , double), T4, T5, RC }		// T4+T5-> C
	    , { 0, 0, 0, 0 }
	};

	for ( i = 100; i--; ) { slice_run(p, 8, D, 2, R, 8); }

	//printf("A\n");
	//print((int *)A.data, NX, NX);
	//printf("B\n");
	//print((int *)B.data, NX, NX);
	//printf("C\n");
	//print((xType *)C.data, NX, NX);
}

