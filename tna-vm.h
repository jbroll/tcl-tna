
#define Min(x, y) (((x) < (y)) ? (x) : (y))

#define RLEN 1024
#define NDIM 5

typedef struct _Axis {
    long	dims;		/* dimensions of the data	*/
    long	star;		/* slice start			*/
    long	incr;		/* increment			*/
    long	size;		/* slice size			*/
    long	step;		/* block size of the dimension	*/
    long	type;		/* byte size of data type	*/
} Axis;

typedef struct _Slice {		/* definition of the slice	*/
    void	*data;
    Axis	 ax[NDIM];
} Slice;

typedef struct _Register {
    void	*offs[NDIM];	/* Offset at this index level	*/
    Slice	 slice;
} Register;

typedef struct _Instr {
    short	opcode;
    short	r1;
    short	r2;
    short	r3;
} Instr;

typedef void OpFunc(int n, Register *r1, Register *r2, Register *r3);

typedef struct _OpTable {
    OpFunc     *func;
    const char *name;
} OpTable;

#define ENUMS_INT(type)		\
      ENUMS_FLT(type)		\
    , INSTR_##mod##_##type	\
    , INSTR_##band##_##type	\
    , INSTR_##bor##_##type	\
    , INSTR_##bxor##_##type	\
    , INSTR_##bnot##_##type

#define ENUMS_FLT(type)		\
    , INSTR_##add##_##type	\
    , INSTR_##sub##_##type	\
    , INSTR_##mul##_##type	\
    , INSTR_##neg##_##type	\
    , INSTR_##equ##_##type	\
    , INSTR_##neq##_##type	\
    , INSTR_##gt##_##type	\
    , INSTR_##lt##_##type	\
    , INSTR_##gte##_##type	\
    , INSTR_##lte##_##type	\
    , INSTR_##div##_##type	\
    , INSTR_##cos##_##type	\
    , INSTR_##sin##_##type	\
    , INSTR_##tan##_##type	\
    , INSTR_##acos##_##type	\
    , INSTR_##asin##_##type	\
    , INSTR_##atan##_##type	\
    , INSTR_##atan2##_##type	\
    , INSTR_##exp##_##type	\
    , INSTR_##log##_##type	\
    , INSTR_##log10##_##type	\
    , INSTR_##pow##_##type	\
    , INSTR_##sqrt##_##type	\
    , INSTR_##ceil##_##type	\
    , INSTR_##abs##_##type	\
    , INSTR_##floor##_##type	\

#define ENUMS_XXX(type)		\
    , INSTR_##xxx##_##type	\

#define ENUMS_CAST(type1, type2)\
    , INSTR_##type1##_##type2

// Name all the opcodes in an enum
//
enum InstructionOp {
    INSTR_NOP = 0
    TYPES_INT(ENUMS_INT)
    TYPES_FLT(ENUMS_FLT)
    TYPES_INT(ENUMS_XXX)
    TYPES_FLT(ENUMS_XXX)
    TYPES_TWO(ENUMS_CAST)
    , INSTR_END
};
