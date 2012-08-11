
#define Min(x, y) (((x) < (y)) ? (x) : (y))

#define NDIM 5

typedef struct _Axis {
    long	star;		/* slice start			*/
    long	size;		/* slice size			*/
    long	incr;		/* increment			*/
    long	step;		/* block size of the dimension	*/
    long	dims;		/* dimension of the data	*/
} Axis;

typedef struct _Register {
    long	 type;		/* data type			*/
    void	*data;		/* pointer to data 		*/
    union	 {
	char	_char;
	uchar	_uchar;
	short	_short;
	ushort	_ushort;
	int	_int;
	uint	_uint;
	long	_long;
	float	_float;
	double	_double;
    } value;
    void	*offs[NDIM];	/* Offset at this index level	*/
    Axis	 axis[NDIM];
} Register;

typedef struct _Instruct {
    short	opcode;
    short	r1;
    short	r2;
    short	r3;
} Instruct;

typedef struct _Dim {
    int	start;
    int	end;

} Dim;

typedef struct _Machine {
    int	   ni;
    Instruct *program;
    int    nr;
    Register *registers;
    Dim    *dims;
    int    nd;
} Machine;


typedef void OpFunc(int n, Register *r1, Register *r2, Register *r3);

typedef struct _OpTable {
    OpFunc     *func;
    const char *name;
} OpTable;



