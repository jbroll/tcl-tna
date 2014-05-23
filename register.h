/* {
   This file will be both included in C and evaluted by Tcl.  Be careful as only
   a thin intersection of C and Tcl are allowed.
} */

#define NDIM 5

typedef struct _Axis {
    long	star;		/* slice start			*/
    long	size;		/* slice size			*/
    long	incr;		/* increment			*/
    long	step;		/* block size of the dimension	*/
    long	dims;		/* dimension of the data	*/
} Axis;

typedef union _Value {
    char	_char;
    uchar	_uchar;
    short	_short;
    ushort	_ushort;
    int		_int;
    uint	_uint;
    long	_long;
    ulong	_ulong;
    float	_float;
    double	_double;
    char*	_string;
} Value;

typedef struct _Data {
    void*	ptr;
    char*	name;
    int		vect;
    double	value;
} Data;
    
typedef struct _Register {
    char 	 type;		/* data type			*/
    char	 item;
    char	 used;
    char*	 name;
    int		 drep;
    Value	 value;
    Data	 data;		/* pointer to data 		*/
    void*	 offs[NDIM+1];	/* Offset at this index level	*/
    Axis	 axis[NDIM];
} Register;

