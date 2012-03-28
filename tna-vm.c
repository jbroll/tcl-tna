
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "generic.h"
#include  "tna-vm.h"

#define R1 *addr1
#define R2 *addr2
#define R3 *addr3

#define INCR			\
    if ( i1 ) { addr1++; }	\
    if ( i2 ) { addr2++; }	\
    if ( i3 ) { addr3++; }

#define INSTR(name, type1, type2, type3 , expr) 					\
    void static name(int n, Register *r1, Register *r2, Register *r3) {			\
	type1	*addr1 = (type1 *)r1->offs[0];						\
	type2	*addr2 = (type2 *)r2->offs[0];						\
	type3	*addr3 = (type3 *)r3->offs[0];						\
	int	 i;									\
											\
	int	i1 = r1->slice.ax[0].size;						\
	int	i2 = r2->slice.ax[0].size;						\
	int	i3 = r3->slice.ax[0].size;						\
											\
	while ( n >= RLEN ) { for ( i = 0; i <  RLEN; i++ ) { expr; INCR } n -= RLEN; }	\
	while ( n >=    8 ) { for ( i = 0; i <     8; i++ ) { expr; INCR }  n -=   8; }	\
											\
	while ( n ) { expr;   n--; INCR }						\
    }


#define INSTRUCTIONS_INT(type)						\
    INSTRUCTIONS_FLT(type)						\
    INSTR(array_mod_##type , type, type, type, R3 = R1 % R2);		\
    INSTR(array_band_##type, type, type, type, R3 = R1 & R2);		\
    INSTR(array_bor_##type , type, type, type, R3 = R1 | R2);		\
    INSTR(array_bxor_##type, type, type, type, R3 = R1 ^ R2);		\
    INSTR(array_bnot_##type, type, type, type, R3 = ~R1 );

#define INSTRUCTIONS_FLT(type)						\
    INSTR(array_add_##type  , type, type, type, R3 = R1 + R2);		\
    INSTR(array_sub_##type  , type, type, type, R3 = R1 - R2);		\
    INSTR(array_mul_##type  , type, type, type, R3 = R1 * R2);		\
    INSTR(array_div_##type  , type, type, type, R3 = R1 / R2);		\
    INSTR(array_neg_##type  , type, type, type, R3 = -(R1));		\
    INSTR(array_equ_##type  , type, type, type, R3 = R1 == R2);		\
    INSTR(array_neq_##type  , type, type, type, R3 = R1 != R2);		\
    INSTR(array_gt_##type   , type, type, type, R3 = R1 > R2);		\
    INSTR(array_lt_##type   , type, type, type, R3 = R1 < R2);		\
    INSTR(array_gte_##type  , type, type, type, R3 = R1 >= R2);		\
    INSTR(array_lte_##type  , type, type, type, R3 = R1 <= R2);		\
    INSTR(array_cos_##type  , type, type, type, R3 =   cos(R1));	\
    INSTR(array_sin_##type  , type, type, type, R3 =   sin(R1));	\
    INSTR(array_tan_##type  , type, type, type, R3 =   tan(R1));	\
    INSTR(array_acos_##type , type, type, type, R3 =  acos(R1));	\
    INSTR(array_asin_##type , type, type, type, R3 =  asin(R1));	\
    INSTR(array_atan_##type , type, type, type, R3 =  atan(R1));	\
    INSTR(array_atan2_##type, type, type, type, R3 = atan2(R1, R2));	\
    INSTR(array_exp_##type  , type, type, type, R3 =   exp(R1));	\
    INSTR(array_log_##type  , type, type, type, R3 =   log(R1));	\
    INSTR(array_log10_##type, type, type, type, R3 = log10(R1));	\
    INSTR(array_pow_##type  , type, type, type, R3 =   pow(R1, R2));	\
    INSTR(array_sqrt_##type , type, type, type, R3 =  sqrt(R1));	\
    INSTR(array_ceil_##type , type, type, type, R3 =  ceil(R1));	\
    INSTR(array_abs_##type  , type, type, type, R3 =   abs(R1));	\
    INSTR(array_floor_##type, type, type, type, R3 = floor(R1));

#define INSTRUCTIONS_XXX(type)					\
    INSTR(array_xxx_##type, int, type, type, R3 = (R1)++);

#define INSTRUCTIONS_CAST(type1, type2)				\
    INSTR(array_##type1##_##type2, type1, type1, type2, R3 = R1);


#define OPCODES_INT(type)				\
      OPCODES_FLT(type)					\
    , { array_##mod##_##type	, "mod_"  #type }	\
    , { array_##band##_##type	, "band_" #type }	\
    , { array_##bor##_##type	, "bor_"  #type }	\
    , { array_##bxor##_##type	, "bxor_" #type }	\
    , { array_##bnot##_##type	, "bnot_" #type }

#define OPCODES_FLT(type)	\
    , { array_##add##_##type	, "add_"   #type }	\
    , { array_##sub##_##type	, "aub_"   #type }	\
    , { array_##mul##_##type	, "mul_"   #type }	\
    , { array_##div##_##type	, "div_"   #type }	\
    , { array_##neg##_##type	, "neg_"   #type }	\
    , { array_##equ##_##type	, "equ_"   #type }	\
    , { array_##neq##_##type	, "neq_"   #type }	\
    , { array_##gt##_##type	, "gt_"    #type }	\
    , { array_##lt##_##type	, "lt_"    #type }	\
    , { array_##gte##_##type	, "gte_"   #type }	\
    , { array_##lte##_##type	, "lte_"   #type }	\
    , { array_##cos##_##type	, "cos_"   #type }	\
    , { array_##sin##_##type	, "sin_"   #type }	\
    , { array_##tan##_##type	, "tan_"   #type }	\
    , { array_##acos##_##type	, "acos_"  #type }	\
    , { array_##asin##_##type	, "asin_"  #type }	\
    , { array_##atan##_##type	, "atan_"  #type }	\
    , { array_##atan2##_##type	, "atan2_" #type }	\
    , { array_##exp##_##type	, "exp_"   #type }	\
    , { array_##log##_##type	, "log_"   #type }	\
    , { array_##log##_##type	, "log10_" #type }	\
    , { array_##pow##_##type	, "pow_"   #type }	\
    , { array_##sqrt##_##type	, "sqrt_"  #type }	\
    , { array_##ceil##_##type	, "ceil_"  #type }	\
    , { array_##abs##_##type	, "abs_"   #type }	\
    , { array_##floor##_##type	, "floor_" #type }

#define OPCODES_XXX(type)				\
    , { array_xxx_##type	, "xxx_"   #type }

#define OPCODES_CAST(type1, type2)			\
    , { array_##type1##_##type2	, #type1 "_" #type2 }


// generate the opcode functions
//
TYPES_INT(INSTRUCTIONS_INT)
TYPES_FLT(INSTRUCTIONS_FLT)
TYPES_INT(INSTRUCTIONS_XXX)
TYPES_FLT(INSTRUCTIONS_XXX)
TYPES_TWO(INSTRUCTIONS_CAST)

// Name all the opcodes in an enum
//
enum InstructionOp {
    INSTR_NOP = 0
    TYPES_INT(ENUMS_INT)
    TYPES_FLT(ENUMS_FLT)
    TYPES_INT(ENUMS_XXX)
    TYPES_FLT(ENUMS_XXX)
    TYPES_TWO(ENUMS_CAST)
};

// Place all the opcode functions in a table with a name for disassembly
//
OpTable OpCodes[] = {
    { NULL, "nop" }
    TYPES_INT(OPCODES_INT)
    TYPES_FLT(OPCODES_FLT)
    TYPES_INT(OPCODES_XXX)
    TYPES_FLT(OPCODES_XXX)
    TYPES_TWO(OPCODES_CAST)
};


void slice_off(Register *r, int d, int x) {
    if ( !r->slice.ax[d].size ) { return; }

    r->offs[d] = ((char *)r->offs[d+1])
  		+ ((r->slice.ax[d].star+((x*r->slice.ax[d].incr)
	        %   r->slice.ax[d].size))
      		%   r->slice.ax[d].dims)
  		*   r->slice.ax[d].step
		*   r->slice.ax[d].type;
}

void slice_run(Instr *program, int ni, int *D, int dim, Register *R, int nregs) 
{
    	int rl;
    	int x, X;
	int nx;
	Instr    *instr;

    dim--;

    nx = R[program[ni-1].r3].slice.ax[dim].size;

    x = 0;
    for ( X = 0; X < nx; ) {				// Run over the entire dimension
	if ( dim ) {
	    int i;

	    D[dim] = X;
	    for ( i = 0; i < nregs; i++ ) { slice_off(&R[i], dim, X); }

	    slice_run(program, ni, D, dim, R, nregs);
	    X++;
	} else {
	    int rl = Min(RLEN, nx - X);

	    x = X;
	    for ( instr = program; instr->opcode; instr++ ) {	// Execute the instructions one bank at a time
		int left = rl;
	        int bite = rl;
		bite     = Min(rl, nx - x);

		if ( R[instr->r1].slice.ax[dim].size ) { bite = Min(bite, R[instr->r1].slice.ax[dim].size); }
		if ( R[instr->r2].slice.ax[dim].size ) { bite = Min(bite, R[instr->r2].slice.ax[dim].size); }
		if ( R[instr->r3].slice.ax[dim].size ) { bite = Min(bite, R[instr->r3].slice.ax[dim].size); }


		for ( ; left > 0; left -= bite ) {	// Run at most the length of the smallest slice
		    D[0] = x;
		    bite = Min(rl, nx - x);

		    slice_off(&R[instr->r1], 0, x);
		    slice_off(&R[instr->r2], 0, x);
		    slice_off(&R[instr->r3], 0, x);


		    OpCodes[instr->opcode].func(bite
			    , &R[instr->r1]
			    , &R[instr->r2]
			    , &R[instr->r3]);

		    x   += bite;
		} 
		x = X;
	    }

	    X += rl;
	}
    }
}

void slice_val(Register *r, void *value) 
{
    	int i;

    for ( i = 0; i < NDIM; i++ ) {
	r->offs[i] = value;
	r->slice.ax[i].size = 0;
    }
}

void slice_reg(Register *r, int type)
{
    slice_val(r, malloc(RLEN * 8));

    r->slice.ax[0].star = 0;
    r->slice.ax[0].incr = 1;
    r->slice.ax[0].size = RLEN;
    r->slice.ax[0].dims = RLEN;
    r->slice.ax[0].step = 1;
    r->slice.ax[0].type = type;
}

void print(double *data, int nx, int ny)  {
	int i, j;

    for ( j = 0; j < ny; j++ ) {
        for ( i = 0; i < ny; i++ ) {
	    printf(" %7.2f", data[j*nx+i]);
        }
	printf("\n");
    }
}

