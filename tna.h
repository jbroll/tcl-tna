
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
    int	 	 type;		/* data type			*/
    int		 item;
    int		 used;
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
    void	*offs[NDIM+1];	/* Offset at this index level	*/
    Axis	 axis[NDIM];
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
    int   *dims;
    int    nd;
} Machine;


typedef void OpFunc(int n, Register *r1, Register *r2, Register *r3);

typedef struct _OpTable {
    OpFunc     *func;
    const char *name;
} OpTable;



