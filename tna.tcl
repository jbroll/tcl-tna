
package provide tna 0.5

critcl::tsources tna.tcl	 			; # This file is a tcl source file for the package.
critcl::tsources tcloo.tcl template.tcl functional.tcl	; # Helpers
critcl::cheaders tna.h 

critcl::cflags -O3
critcl::clibraries -lm

source tcloo.tcl
source template.tcl

namespace eval tna {
    set regsize 1024

    # This array defines the types available in the package.
    #
    #       tnaType CType         	pType	pFmt	getType	getFunc
    set Types {
	      char  char              	int     %d 	int	Tcl_GetIntFromObj
	     uchar "unsigned char"    	int     %d 	int	Tcl_GetIntFromObj 
	     short  short		int     %d 	int	Tcl_GetIntFromObj 
	    ushort "unsigned short"	int     %d 	int	Tcl_GetIntFromObj 
	       int  int 		int     %d 	int	Tcl_GetIntFromObj 
	      uint "unsigned int"	long    %u 	long	Tcl_GetLongFromObj 
	      long  long		long   %ld 	long	Tcl_GetLongFromObj 
	     float  float		double  %f 	double	Tcl_GetDoubleFromObj 
	    double  double		double  %f 	double	Tcl_GetDoubleFromObj 
    }

    set IntOnly { mod band bor bxor bnot shr shl }

    set Opcodes {
	mod	{ R3 = R1 %  R2; 	}
	band	{ R3 = R1 &  R2; 	}
	bor 	{ R3 = R1 |  R2; 	}
	bxor	{ R3 = R1 ^  R2; 	}
	bnot	{ R3 = ~R1;	 	}
	shr	{ R3 = R1 >> R2; 	}
	shl	{ R3 = R1 << R2; 	}

	add	{ R3 = R1 + R2;		}
	sub	{ R3 = R1 - R2;		}
	mul 	{ R3 = R1 * R2;		}
	div 	{ R3 = R1 / R2;		}
	neg 	{ R3 = -(R1);		}
	equ 	{ R3 = R1 == R2;	}
	neq 	{ R3 = R1 != R2;	}
	gt 	{ R3 = R1 > R2;		}
	lt 	{ R3 = R1 < R2;		}
	gte 	{ R3 = R1 >= R2;	}
	lte 	{ R3 = R1 <= R2;	}
	land	{ R3 = (int)R1 && (int)R2;	}
	lor 	{ R3 = (int)R1 || (int)R2;	}
	cos 	{ R3 =   cos(R1);	}
	sin 	{ R3 =   sin(R1);	}
	tan 	{ R3 =   tan(R1);	}
	acos 	{ R3 =  acos(R1);	}
	asin 	{ R3 =  asin(R1);	}
	atan 	{ R3 =  atan(R1);	}
	atan2	{ R3 = atan2(R1, R2);	}
	exp	{ R3 =   exp(R1);	}
	log 	{ R3 =   log(R1);	}
	log10	{ R3 = log10(R1);	}
	pow	{ R3 =   pow(R1, R2);	}
	sqrt	{ R3 =  sqrt(R1);	}
	ceil	{ R3 =  ceil(R1);	}
	abs	{ R3 =   abs(R1);	}
	floor	{ R3 = floor(R1);	}
	xxx	{ R3 = (R1)++;		}
    }

    set  axes { x y z u v }		; # The names of the axis index variables
    set naxes [llength $axes]


    proc opcodes {} {
	set opcodes {}

	foreach { type CType  pType   pFmt    getType getFunc } $tna::Types {
	    foreach { name code } $::tna::Opcodes {
		set T $type

		if { $name in $tna::IntOnly && $type in { float double } } { continue }
		if { $name eq "xxx" } { set T int }

		lappend opcodes $name $T $type $code
	    }

	    foreach { type2 CType pType   pFmt    getType getFunc } $::tna::Types {
		lappend opcodes $type $type $type2 { R3 = R1 }
	    }
	}

	return $opcodes
    }

    critcl::ccode {
	#include <stdlib.h>
	#include <stdio.h>
	#include <math.h>
    }
    critcl::ccode "#define RLEN $regsize"

    set i 1
    foreach { type ctype pType   pFmt    getType getFunc } $::tna::Types { 

	# Create a proc to allocate memory, and return the sizeof each type
	#
	critcl::cproc malloc_$type { long size } long "return (long) malloc(size*sizeof($ctype));"
	critcl::cproc sizeof_$type { long size } long "return sizeof($ctype);"

	# Add typedefs for any that are not C primitive types
	#
	if { $type ne $ctype } { critcl::ccode "typedef $ctype $type;\n" }

	# Make an array to look up the types enumerated value from tcl.
	#
	set ::tna::Type($type) $i

	# For use in the body of slice_offs
	#
	critcl::ccode "#define TNA_TYPE_$type $i"
	append TypeCases "case TNA_TYPE_$type:	(*($ctype   *)r->offs) = x;	break;\n"

	incr i
    }

}

critcl::ccode {

    #include "/Users/john/src/tna/tna.h"		/* The cheaders directive above didn't seem to take?	*/

    #define R1 *addr1
    #define R2 *addr2
    #define R3 *addr3

    #define INCR		\
	if ( i1 ) { addr1++; }	\
	if ( i2 ) { addr2++; }	\
	if ( i3 ) { addr3++; }

    #define INSTR(name, type1, type2, type3 , expr) 						\
	void static name(int n, Register *r1, Register *r2, Register *r3) {			\
	    type1	*addr1 = (type1 *)r1->offs[0];						\
	    type2	*addr2 = (type2 *)r2->offs[0];						\
	    type3	*addr3 = (type3 *)r3->offs[0];						\
	    int	 i;										\
												\
	    int	i1 = r1->axis[0].size;							\
	    int	i2 = r2->axis[0].size;							\
	    int	i3 = r3->axis[0].size;							\
												\
	    while ( n >= RLEN ) { for ( i = 0; i <  RLEN; i++ ) { expr; INCR } n -= RLEN; }	\
	    while ( n >=    8 ) { for ( i = 0; i <     8; i++ ) { expr; INCR }  n -=   8; }	\
												\
	    while ( n ) { expr;   n--; INCR }							\
	}
}
critcl::ccode [subst {
    [: { name type type2 code } [tna::opcodes] {
	    INSTR(tna_opcode_${name}_${type2}, $type, $type, $type2, $code)
    }]

    OpTable OpCodes\[] = {
	{ NULL, "nop" }
	[: { name type type2 code } [tna::opcodes] {	, { tna_opcode_${name}_${type2}, "tna_opcode_${name}_${type2}" }\n}]
    };
}]

critcl::ccode [string map [list %TypeCases $::tna::TypeCases] {
    void slice_off(Register *r, int d, int x) {
	if ( r->axis[d].size == -(d+1) ) {
	    switch ( r->type ) {		// Slice index access from a typed Value register.
		%TypeCases
	    }
	}
	if ( !r->axis[d].size ) { return; }		// no need to adjust offset of a Value or temp register.

	r->offs[d] = ((char *)r->offs[d+1])		// Adjust offset into Array type.
		    + ((r->axis[d].star+((x*r->axis[d].incr)
		    %   r->axis[d].size))
		    %   r->axis[d].dims)
		    *   r->axis[d].step
		    *   r->type;
    }
}]

critcl::ccode {
    void slice_val(Register *r, void *value) 
    {
	    int i;

	for ( i = 0; i < NDIM; i++ ) {
	    r->offs[i] = value;
	    r->axis[i].size = 0;
	}
    }

    void slice_reg(Register *r, int type)
    {
	slice_val(r, malloc(RLEN * 8));

	r->type = type;

	r->axis[0].star = 0;
	r->axis[0].incr = 1;
	r->axis[0].size = RLEN;
	r->axis[0].dims = RLEN;
	r->axis[0].step = 1;
    }


    void slice_run(Machine *machine, int dim)
    {
	    Instruct *program = machine->program;
	    int       ni = machine->ni;
	    Register *R  = machine->registers;
	    int       nr = machine->nr;

	    int rl;
	    int x, X;
	    int X1;
	    Instruct *instr;

	dim--;

	x  =     machine->dims[dim].start;
	X1 = x + machine->dims[dim].end;
	for ( X = 0; X < X1; ) {				// Run over the entire dimension
	    if ( dim ) {
		int i;

		for ( i = 0; i < nr; i++ ) { slice_off(&R[i], dim, X); }

		slice_run(machine, dim);
		X++;
	    } else {
		int rl = Min(RLEN, X1 - X);

		x = X;
		for ( instr = program; instr->opcode; instr++ ) {	// Execute the instructions one bank at a time
		    int left = rl;
		    int bite = rl;
		    bite     = Min(rl, X1 - x);

		    if ( R[instr->r1].axis[dim].size ) { bite = Min(bite, R[instr->r1].axis[dim].size); }
		    if ( R[instr->r2].axis[dim].size ) { bite = Min(bite, R[instr->r2].axis[dim].size); }
		    if ( R[instr->r3].axis[dim].size ) { bite = Min(bite, R[instr->r3].axis[dim].size); }


		    for ( ; left > 0; left -= bite ) {	// Run at most the length of the smallest slice
			bite = Min(rl, X1 - x);

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

    void print(double *data, int nx, int ny)  {
	    int i, j;

	for ( j = 0; j < ny; j++ ) {
	    for ( i = 0; i < ny; i++ ) {
		printf(" %7.2f", data[j*nx+i]);
	    }
	    printf("\n");
	}
    }

}

namespace eval tna {
    critcl::cproc opcodesX { Tcl_Interp* ip } void {
	int i;
	Tcl_Obj *tnaOpcodes = Tcl_NewStringObj("::tna::OpcodesX", -1);

	for ( i = 0; i < sizeof(OpCodes)/sizeof(OpCodes[0]); i++ ) {
	    Tcl_Obj *opname = Tcl_NewStringObj(OpCodes[i].name, -1);
	    Tcl_Obj *opcode = Tcl_NewIntObj(i);

	    Tcl_ObjSetVar2(ip, tnaOpcodes, opname, opcode, TCL_GLOBAL_ONLY);
	}
    }

    critcl::cproc execute { Tcl_Interp* ip Tcl_Obj* regsList Tcl_Obj* textList } ok [template:subst {
	int 	i, s;
	int 	nregs;
	int 	ntext;

	int      regsObjc;
	Tcl_Obj **regsObjv;

	Tcl_Obj **textObjv;

	Register*regs;

	short	*text;
	int	 thisInt;
	long	 thisLong;

	int	itemType;
	int	dataType;

	double dataValu;

	int	ndim = 0;

	// Copy the registers Tcl structure into the Register C struct.
	//
	if ( Tcl_ListObjGetElements(ip, regsList, &nregs, &regsObjv) == TCL_ERROR ) { return TCL_ERROR; }

	regs = malloc(sizeof(Register) * nregs);

	for ( i = 0; i < nregs; i++ ) {
	    int	     leng;
	    int      regObjc;
	    Tcl_Obj **regObjv;

	    if ( Tcl_ListObjGetElements(ip, regsObjv[i], &regObjc, &regObjv) == TCL_ERROR ) { return TCL_ERROR; }

	    // reg typ itm : obj dat dim slice
	    //
	    if ( Tcl_GetIntFromObj( ip, regObjv[6], &thisInt ) == TCL_ERROR ) {
		free(regs);
		return TCL_ERROR;
	    }
	    itemType = thisInt;

	    if ( Tcl_GetIntFromObj( ip, regObjv[7], &thisInt ) == TCL_ERROR ) {
		free(regs);
		return TCL_ERROR;
	    }
	    dataType = thisInt;


#define NoneRegister	0
#define TempRegister	1
#define ValuRegister	2
#define DataRegister	3


	    switch ( itemType ) {
	     case TempRegister: slice_reg(&regs[i], dataType);	 break;
	     case ValuRegister:
		switch ( dataType ) {
		    [: { type ctype pType   pFmt    getType getFunc } $::tna::Types {

		     case TNA_TYPE_$type: {
			$getType this;

			if ( ${getFunc}(ip, regObjv[4], &this) == TCL_ERROR ) {
			    free(regs);
			    return TCL_ERROR;
			}
			regs[i].value._$type = this;
			break;
		      }
		    }]
		}
		slice_val(&regs[i], (void *)&regs[i].value);
		break;

	     case DataRegister: {
		    int       sObjc;
		    Tcl_Obj **sObjv;

		/* Unpack the slice data	*/

		if ( Tcl_ListObjGetElements(ip, regObjv[9], &sObjc, &sObjv) == TCL_ERROR ) {
		    free(regs);
		    return TCL_ERROR;
		}

		if ( ndim < sObjc ) { ndim = sObjc; }

		for ( s = 0; s < sObjc; s++ ) {
		    int       sliceObjc;
		    Tcl_Obj **sliceObjv;

		    if ( Tcl_ListObjGetElements(ip, sObjv[s], &sliceObjc, &sliceObjv) == TCL_ERROR ) {
			free(regs);
			return TCL_ERROR;
		    }
		    if ( sliceObjc != 3 ) {
			Tcl_AddErrorInfo(ip, "each slice should have 3 values");
			free(regs);
			return TCL_ERROR;
		    }

		    if ( Tcl_GetIntFromObj(ip, sliceObjv[0], &thisInt ) == TCL_ERROR ) {
			free(regs);
			return TCL_ERROR;
		    }
		    regs[i].axis[s].star = thisInt;

		    if ( Tcl_GetIntFromObj(ip, sliceObjv[1], &thisInt ) == TCL_ERROR ) {
			free(regs);
			return TCL_ERROR;
		    }
		    regs[i].axis[s].size = thisInt - regs[i].axis[0].star;

		    if ( Tcl_GetIntFromObj(ip, sliceObjv[2], &thisInt ) == TCL_ERROR ) {
			free(regs);
			return TCL_ERROR;
		    }
		    regs[i].axis[s].incr = thisInt;
		}
		
		break;
	     }
	    }
	}

	// Convert the textList into an array of shorts.
	//
	if ( Tcl_ListObjGetElements(ip, textList, &ntext, &textObjv) == TCL_ERROR ) { return TCL_ERROR; }

	text = malloc(sizeof(short) * ntext);

	for ( i = 0; i < ntext; i++ ) {
	    if ( Tcl_GetIntFromObj(ip, textObjv[i], &thisInt) == TCL_ERROR ) {
		free(text);
		free(regs);
		return TCL_ERROR;
	    }

	    text[i] = thisInt;
	}

	for ( i = 0 ; i < nregs; i++ ) {
	    int j;

	    printf("%d\n", i);
	    for ( j = 0; j < ndim; j++ ) {
		printf("	%ld : %ld\n", regs[i].axis[j].star, regs[i].axis[j].size);
	    }
	}
	{
	    Machine m;
	    Dim	    dims;

	    m.program   =  text;
	    m.ni        = ntext;
	    m.registers = regs;
	    m.nr        = nregs;

	    m.dims	= &dims;
	    m.nd	= ndim;

	    slice_run(&m, ndim);
	}

	return TCL_OK;
    }]
}



if { [::critcl::compiled] } {
    ::tna::opcodesX
    set i 0
    foreach { tnaType CType pType pFmt getType getFunc } $::tna::Types {
	set ::tna::TypesX($tnaType) [incr i]
    }
}


