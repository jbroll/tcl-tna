
#define Min(x, y) (((x) < (y)) ? (x) : (y))

#define NDIM 5

typedef struct _Axis {
    long	star;		/* slice start			*/
    long	size;		/* slice size			*/
    long	incr;		/* increment			*/
    long	step;		/* block size of the dimension	*/
    long	type;		/* byte size of data type	*/
    long	dims;		/* dimension of the data	*/
} Axis;

typedef struct _Slice {		/* definition of the slice	*/
    void	*data;
    Axis	 ax[NDIM];
} Slice;

typedef struct _Register {
    void	*offs[NDIM];	/* Offset at this index level	*/
    Slice	 slice;
} Register;

typedef struct _Instruct {
    short	opcode;
    short	r1;
    short	r2;
    short	r3;
} Instruct;

typedef struct _Machine {
    int	   ni;
    Instruct *program;
    int    nr;
    Register *registers;
    int    X0[NDIM];
    int    X1[NDIM];
} Machine;


typedef void OpFunc(int n, Register *r1, Register *r2, Register *r3);

typedef struct _OpTable {
    OpFunc     *func;
    const char *name;
} OpTable;

