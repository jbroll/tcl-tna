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

typedef union _ARecValue {
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
} ARecValue;
    
typedef struct _Register {
    int	 	 type;		/* data type			*/
    int		 item;
    int		 used;
    void*	 data;		/* pointer to data 		*/
    Tcl_Obj*	 name;
    ARecValue	 value;
    void*	 offs[NDIM+1];	/* Offset at this index level	*/
    Axis	 axis[NDIM];
} Register;
