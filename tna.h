
#define Min(x, y) (((x) < (y)) ? (x) : (y))

#define NDIM 5

#include "tna-register.h"


typedef struct _Instruct {
    short		opcode;
    unsigned char	size;
    unsigned char	r1;
    unsigned char	r2;
    unsigned char	r3;
} Instruct;

typedef struct _Machine {
    Instruct *program;
    int    nr;
    Register *registers;
    int   *zero;
    int   *dims;
    int    nd;
} Machine;


typedef void OpFunc(Instruct *ip, int n, Register *r1, Register *r2, Register *r3);

typedef struct _OpTable {
    OpFunc     *func;
    const char *name;
} OpTable;
