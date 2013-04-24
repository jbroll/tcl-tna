
package provide tna 0.5

critcl::tsources tcloo.tcl tna.tcl tna-register.unsourced tna-tcl.tcl  			; # This file is a tcl source file for the package.
critcl::cheaders tna.h tna-register.h tpool/tpool.h
critcl::csources tpool/tpool.c

critcl::cflags -O3 -DTCL_THREADS=1
critcl::clibraries -lm

source functional.tcl
source template.tcl

namespace eval tna {
    set debug    0

    set regsize 512

    set  Axes { X Y Z U V }		; # The names of the axis index variables
    set nAxes [llength $Axes]

    # This array defines the types available in the package.
    #
    #       tnaType CType         	pType	pFmt	getType	getFunc			scan
    set Types {
	      char  char              	int     %d 	int	Tcl_GetIntFromObj	c
	     uchar "unsigned char"    	int     %d 	int	Tcl_GetIntFromObj	c 
	     short  short		int     %d 	int	Tcl_GetIntFromObj	s 
	    ushort "unsigned short"	int     %d 	int	Tcl_GetIntFromObj	s 
	       int  int 		int     %d 	int	Tcl_GetIntFromObj	i
	      uint "unsigned int"	long    %u 	long	Tcl_GetLongFromObj	i 
	      long "long"		long   %ld 	long	Tcl_GetLongFromObj	i 
	     ulong "unsigned long"	long   %lu 	long	Tcl_GetLongFromObj	i
	     float  float		double  %f 	double	Tcl_GetDoubleFromObj	f 
	    double  double		double  %f 	double	Tcl_GetDoubleFromObj	d 
    }

    variable IntOnly { mod band bor bxor bnot shr shl }

    set Opcodes {
	mod	{ R3 = R1 %  R2 	}
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
	usub 	{ R3 = -(R1);		}
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


    proc opcodes {} {
	set opcodes {}

	foreach { type CType  pType   pFmt    getType getFunc scan } $tna::Types {
	    foreach { name code } $::tna::Opcodes {
		set T $type

		if { $name in $tna::IntOnly && $type in { float double } } { continue }
		if { $name eq "xxx" } { set T int }

		lappend opcodes $name $T $type $code
	    }

	    foreach { type2 CType pType   pFmt    getType getFunc scan } $::tna::Types {
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

    critcl::cproc bap  { Tcl_Obj* bytes } long { return (long) Tcl_GetByteArrayFromObj(bytes, NULL); }

    critcl::cproc free { long data } void { free((void *) data); }

    foreach { type ctype pType   pFmt    getType getFunc scan } $::tna::Types i [iota 1 [::expr [llength $::tna::Types]/7]] { 

	# Create a proc to allocate memory, and return the sizeof each type
	#
	critcl::cproc sizeof_$type {} int [subst { return sizeof($ctype); }]
	critcl::cproc malloc_$type { long size } long [subst { return (long) calloc(size, sizeof($ctype)); }]

	# Add typedefs for any that are not C primitive types
	#
	if { $type ne $ctype } { critcl::ccode "typedef $ctype $type;\n" }

	# Make an array to look up the types enumerated value from tcl.
	#
	set ::tna::Type($type) $i

	# For use in the body of slice_offs
	#
	critcl::ccode "#define TNA_TYPE_$type $i"
	append TypeCases "case TNA_TYPE_$type:	r->value._$type = x;	break;\n"
    }

    critcl::ccode [template:subst {

	#define RLEN $::tna::regsize

	#include "tna.h"		/* The cheaders directive above didn't seem to take?	*/
	#include "tpool.h"

	static TPool *tp = NULL;
	static nthread   = 1;

	int SizeOf[] = {
	    0 [: { type ctype pType   pFmt    getType getFunc scan } $::tna::Types { , sizeof($type) }]
	};

	rprint(Register *r, int n) {
	    int i;

	    printf("%p data %p item %d type %d sizeof %d\n"
		    , r
		    , r->data
		    , r->item
		    , r->type
		    , SizeOf[r->type]
		);
	    for ( i = 0; i <= n; i++ ) {
		printf("	star %ld size %ld incr %ld dims %ld step %ld		%p\n"
		    , r->axis[i].star, r->axis[i].size, r->axis[i].incr, r->axis[i].dims, r->axis[i].step, r->offs[i]);
	    }
	    printf("	%p\n", r->offs[i]);
	}

	void slice_val(Register *r, int type, void *value) 	// Initialize a register to access a value
	{
		int i;

	    r->type = type;
	    r->data = value;

	    for ( i = 0; i < NDIM; i++ ) {
		r->offs[i] = value;
		r->axis[i].star = 0;
		r->axis[i].incr = 0;
		r->axis[i].size = 0;
		r->axis[i].dims = 0;
		r->axis[i].step = 0;
	    }
	    r->offs[i] = value;
	}

	void slice_reg(Register *r, int type)			// Initialize a register as a temperary
	{
	    slice_val(r, type, malloc(RLEN * 8));

	    r->axis[0].star = 0;
	    r->axis[0].incr = 1;
	    r->axis[0].size = RLEN;
	    r->axis[0].dims = RLEN;
	    r->axis[0].step = 1;
	}

	void slice_off(Register *r, int d, int x) {		// Initialize a register as a slice of an array.
	    if ( r->axis[d].size == -(d+1) ) {
		switch ( r->type ) {				// Slice index access from a typed Value register.
		    $::tna::TypeCases
		    default: printf("Unknown register type %d\n", r->type);
			     break;
		}
	    }

	    if ( r->axis[d].size <= 0 ) { return; }		// no need to adjust offset of a Value or temp register.

	    r->offs[d] = ((char *)r->offs[d+1])			// Adjust offset into Array type.
			+ ((r->axis[d].star+((x*r->axis[d].incr)
			%   r->axis[d].size))
			%   r->axis[d].dims)
			*   r->axis[d].step
			*   SizeOf[r->type];

		if ( 0 ) {
		    printf("_off %p %d %p : %p, star %ld x %d incr %ld size %ld dims %ld step %ld type %d\n"
			    , r, d, r->data, r->offs[d]
			    , r->axis[d].star, x
			    , r->axis[d].incr
			    , r->axis[d].size
			    , r->axis[d].dims
			    , r->axis[d].step
			    , SizeOf[r->type]
			  );
		}
	}


	#define R1 *addr1
	#define R2 *addr2
	#define R3 *addr3

	  #define INCR	\
	    addr1 += i1;	\
	    addr2 += i2;	\
	    addr3 += i3;

	#define INSTR(name, type1, type2, type3 , expr) 					\
	    void static name(Instruct *ip, int n, Register *r1, Register *r2, Register *r3) {	\
		type1	*addr1 = (type1 *)r1->offs[0];						\
		type2	*addr2 = (type2 *)r2->offs[0];						\
		type3	*addr3 = (type3 *)r3->offs[0];						\
												\
		int	i1 = r1->axis[0].incr;							\
		int	i2 = r2->axis[0].incr;							\
		int	i3 = r3->axis[0].incr;							\
												\
		for ( ; n; n-- ) { expr; INCR }							\
	    }
    }]
    critcl::ccode [subst {
	[: { name type type2 code } [tna::opcodes] {
		INSTR(tna_opcode_${name}_${type2}, $type, $type, $type2, $code)
	}]

	OpTable OpCodes\[] = {
	    { NULL, "nop" }
	    [: { name type type2 code } [tna::opcodes] {	, { tna_opcode_${name}_${type2}, "tna_opcode_${name}_${type2}" }\n}]
	};

    }]

    critcl::ccode {

	void slice_run(Machine *machine, int dim)
	{
		Instruct *program = machine->program;
		Register *R  = machine->registers;
		int       nr = machine->nr;

		int rl;
		int x, X;
		int X0, X1;
		short    *ip;
		Instruct *instr;

	    dim--;

	    X0 = machine->zero[dim];
	    X1 = machine->dims[dim];

	    for ( X = X0; X < X1; ) {				// Run over the entire dimension
		if ( dim ) {
		    int i;

		    for ( i = 0; i < nr; i++ ) { slice_off(&R[i], dim, X); }

		    slice_run(machine, dim);
		    X++;
		} else {
		    int rl = Min(RLEN, X1 - X);

		    x = X;

		    for ( instr = program;
			  instr->opcode;
			  instr = (Instruct *) ((char *) instr + instr->size) ) {	// Execute the instructions one bank at a time
			int left = rl;
			int bite = rl;
			bite     = Min(rl, X1 - x);

			if ( R[instr->r1].axis[dim].size > 1 ) { bite = Min(bite, R[instr->r1].axis[dim].size); }
			if ( R[instr->r2].axis[dim].size > 1 ) { bite = Min(bite, R[instr->r2].axis[dim].size); }
			if ( R[instr->r3].axis[dim].size > 1 ) { bite = Min(bite, R[instr->r3].axis[dim].size); }

			//printf("R1 %d\n", R[instr->r1].axis[dim].size);
			//printf("R2 %d\n", R[instr->r2].axis[dim].size);
			//printf("R3 %d\n", R[instr->r3].axis[dim].size);
			//printf("Bite : %d\n", bite);

			for ( ; left > 0; left -= bite ) {	// Run at most the length of the smallest slice
			    bite = Min(bite, X1 - x);

			    slice_off(&R[instr->r1], 0, x);
			    slice_off(&R[instr->r2], 0, x);
			    slice_off(&R[instr->r3], 0, x);

			    //printf("%d %d %d %d\n", instr->opcode, instr->r1, instr->r2, instr->r3);

			    OpCodes[instr->opcode].func(
				      instr
				    , bite
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
	void slice_thr(Machine *machine) { slice_run(machine, machine->nd); }
    }

    critcl::cproc opcodesX { Tcl_Interp* ip } void {
	int i;
	Tcl_Obj *tnaOpcodes = Tcl_NewStringObj("::tna::OpcodesX", -1);

	for ( i = 0; i < sizeof(OpCodes)/sizeof(OpCodes[0]); i++ ) {
	    Tcl_Obj *opname = Tcl_NewStringObj(OpCodes[i].name, -1);
	    Tcl_Obj *opcode = Tcl_NewIntObj(i);

	    Tcl_ObjSetVar2(ip, tnaOpcodes, opname, opcode, TCL_GLOBAL_ONLY);
	}
    }

    critcl::cproc nthread { int n } void { nthread = n; }

    critcl::cproc execute { Tcl_Interp* ip Tcl_Obj* regsList Tcl_Obj* textList } ok [template:subst {
	int 	i, s, j;
	int 	nregs;
	int 	ntext;

	long	data;

	int      regsObjc;
	Tcl_Obj **regsObjv;

	Tcl_Obj **textObjv;

	Register *regs;

	Instruct *text;
	int	 thisInt;
	long	 thisLong;

	char    *itemType;
	int	dataType;

	double dataValu;

	int	ndim = 0;

	if ( !tp ) { tp = TPoolInit(16); }

	// Copy the registers Tcl structure into the Register C struct.
	//
	if ( Tcl_ListObjGetElements(ip, regsList, &nregs, &regsObjv) == TCL_ERROR ) { return TCL_ERROR; }

	regs = calloc(nregs, sizeof(Register));

	for ( i = 0; i < nregs; i++ ) {
	    int	     leng;
	    int      regObjc;
	    Tcl_Obj **regObjv;

	    if ( Tcl_ListObjGetElements(ip, regsObjv[i], &regObjc, &regObjv) == TCL_ERROR ) { return TCL_ERROR; }

	    // reg typ item name : drep data obj dat dim slice
	    //
	    itemType = Tcl_GetStringFromObj(regObjv[2], NULL);
	    regs[i].item = itemType[0];

	    if ( Tcl_GetIntFromObj( ip, regObjv[8], &dataType ) == TCL_ERROR ) {
		free(regs);
		return TCL_ERROR;
	    }

	    switch ( regs[i].item ) {

	     case 'a': slice_reg(&regs[i], dataType);	 break;				// anon
	     case 'v':									// vect
		if ( Tcl_GetLongFromObj( ip, regObjv[6], &data ) == TCL_ERROR ) {	
		    free(regs);
		    return TCL_ERROR;
		}

		slice_val(&regs[i], dataType, (void *)&regs[i].value);
		for ( j = 0; j < NDIM; j++ ) { regs[i].axis[j].size = data; }

		break;

	     case 'i':									// ivar
	     case 'o':									// ovar
	     case 'x':									// xvar
	     case 'c': {								// const
		Tcl_Obj *tclValue;

		if ( regs[i].item == 'c' ) {					
		    tclValue = regObjv[6];
		} else {
		    regs[i].name = regObjv[6];
		    if ( !(tclValue = Tcl_ObjGetVar2(ip, regObjv[6], NULL, 0)) ) {
			Tcl_Obj *error = Tcl_NewStringObj("can't read \"", -1);
			Tcl_AppendObjToObj(error, regObjv[6]);
			Tcl_AppendObjToObj(error, Tcl_NewStringObj("\": no such variable", -1));
			Tcl_SetObjResult(ip, error);
			return TCL_ERROR;
		    }
		}

		switch ( regs[i].item ) {
		 case 'i':
		 case 'x':
		 case 'c':
		    switch ( dataType ) {
			[: { type ctype pType   pFmt    getType getFunc scan } $::tna::Types {

			 case TNA_TYPE_$type: {
			    $getType this;

			    if ( ${getFunc}(ip, tclValue, &this) == TCL_ERROR ) {
				free(regs);
				return TCL_ERROR;
			    }
			    regs[i].value._$type = this;
			    break;
			  }
			}]
		    }
		    break;
		}
		slice_val(&regs[i], dataType, (void *)&regs[i].value);
		break;
	     }

	     case 't': {
		    int       dObjc;
		    Tcl_Obj **dObjv;

		    int       sObjc;
		    Tcl_Obj **sObjv;

		regs[i].type = dataType;

		if ( !strcmp(Tcl_GetStringFromObj(regObjv[5], NULL), "bytes") ) {
		    regs[i].data = Tcl_GetByteArrayFromObj(regObjv[6], NULL);
		} else {
		    if ( Tcl_GetLongFromObj( ip, regObjv[6], &regs[i].data ) == TCL_ERROR ) {
			free(regs);
			return TCL_ERROR;
		    }
		}

		/* Unpack the dims and slice data	*/

		if ( Tcl_ListObjGetElements(ip, regObjv[9], &dObjc, &dObjv) == TCL_ERROR ) {
		    free(regs);
		    return TCL_ERROR;
		}
		if ( Tcl_ListObjGetElements(ip, regObjv[10], &sObjc, &sObjv) == TCL_ERROR ) {
		    free(regs);
		    return TCL_ERROR;
		}

		if ( sObjc != dObjc ) {
		    Tcl_AddErrorInfo(ip, "dims and slice dimensions must match");
		    free(regs);
		    return TCL_ERROR;
		}

		if ( ndim < sObjc ) { ndim = sObjc; }

		for ( s = 0; s <= NDIM; s++ ) {
		    regs[i].offs[s] = regs[i].data;
		}
		for ( s = 0; s <  NDIM; s++ ) {
		    regs[i].axis[s].star = 0;
		    regs[i].axis[s].size = 0;
		    regs[i].axis[s].incr = 0;
		    regs[i].axis[s].step = 0;
		    regs[i].axis[s].dims = 0;
		}


		for ( s = 0; s < sObjc; s++ ) {
		    int       sliceObjc;
		    Tcl_Obj **sliceObjv;

		    if ( Tcl_GetIntFromObj(ip, dObjv[s], &thisInt ) == TCL_ERROR ) {
			free(regs);
			return TCL_ERROR;
		    }
		    regs[i].axis[s].dims = thisInt;

		    if ( s ) { regs[i].axis[s].step = regs[i].axis[s-1].step * regs[i].axis[s-1].dims;
		    } else   { regs[i].axis[s].step = 1; }


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
		    if ( regs[i].axis[s].star <= thisInt ) {
			regs[i].axis[s].size = thisInt - regs[i].axis[s].star + 1;
		    } else {
			regs[i].axis[s].size = thisInt - regs[i].axis[s].star - 1;
		    }

		    if ( Tcl_GetIntFromObj(ip, sliceObjv[2], &thisInt ) == TCL_ERROR ) {
			free(regs);
			return TCL_ERROR;
		    }
		    regs[i].axis[s].incr = thisInt;

		    if ( regs[i].axis[s].size < 0 ) {
			regs[i].axis[s].size = -(regs[i].axis[s].size);
			regs[i].axis[s].incr = -(regs[i].axis[s].incr);
		    }


		    regs[i].offs[s] = regs[i].data;
		}
		
		break;
	     }
	     default : {
		Tcl_Obj *error = Tcl_NewStringObj("unknown item type register:", -1);
		Tcl_AppendObjToObj(error, regObjv[0]);
		Tcl_AppendObjToObj(error, regObjv[1]);
		Tcl_AppendObjToObj(error, regObjv[2]);
		Tcl_AppendObjToObj(error, regObjv[3]);
		Tcl_SetObjResult(ip, error);
		free(regs);
		return TCL_ERROR;
	     }
	    }
	}

	// Convert the text program into an array of Instruct.
	//
	if ( Tcl_ListObjGetElements(ip, textList, &ntext, &textObjv) == TCL_ERROR ) {
	    free(regs);
	    return TCL_ERROR;
	}


	text = calloc(ntext+1, sizeof(Instruct));

	for ( i = 0; i < ntext; i++ ) {
	        int j;
		int       iObjc;
		Tcl_Obj **iObjv;

		unsigned char *r = &text[i].r1;

	    if ( Tcl_ListObjGetElements(ip, textObjv[i], &iObjc, &iObjv) == TCL_ERROR ) {
		free(text);
		free(regs);
		return TCL_ERROR;
	    }

	    if ( Tcl_GetIntFromObj(ip, iObjv[0], &thisInt) == TCL_ERROR ) {
		free(text);
		free(regs);
		return TCL_ERROR;
	    }
	    text[i].opcode = thisInt;
	    text[i].size = 1 + (iObjc+1);

	    for ( j = 0; j < iObjc-1; j++ ) {
		if ( Tcl_GetIntFromObj(ip, iObjv[j+1], &thisInt) == TCL_ERROR ) {
		    free(text);
		    free(regs);
		    return TCL_ERROR;
		}
		r[j] = thisInt;
		regs[thisInt].used = 1;
	    }
	}

	{   int	           k;
	    Machine        m[16];
	    int	    dims[16][NDIM];
	    int	    zero[16][NDIM];
	    TPoolThread *thr[16];

	    int	    ndim = 0;

	    for ( j = 0; j < NDIM;  j++ ) {
		zero[0][j] = 0;
		dims[0][j] = 0;
		for ( i = 0; i < nregs; i++ ) {
		    if ( regs[i].used && regs[i].item == 't' && dims[0][j] < regs[i].axis[j].size ) {
			dims[0][j] = regs[i].axis[j].size;
		    }
		}
		if ( dims[0][j] != 0 ) { ndim = j+1; }
	    }
	    if ( ndim == 0 ) {
		ndim = 1;
		dims[0][0] = 1;
	    }

	    m[0].program   = (Instruct *) text;
	    m[0].registers = regs;
	    m[0].nr        = nregs;
	    m[0].zero	   = zero[0];
	    m[0].dims	   = dims[0];
	    m[0].nd	   = ndim;
	    
	    for ( k = 1; k < nthread; k++ ) {
		memcpy(dims[k], dims[k-1], NDIM*sizeof(int));
		memcpy(zero[k], zero[k-1], NDIM*sizeof(int));

		dims[k  ][ndim-1] = dims[k-1][ndim-1];
		zero[k  ][ndim-1] = zero[k-1][ndim-1] + dims[k  ][ndim-1]/nthread;
		dims[k-1][ndim-1] = zero[k  ][ndim-1];

		regs = malloc(nregs*sizeof(Register));
		memcpy(regs, m[0].registers, nregs*sizeof(Register));

		for ( i = 0; i < nregs; i++ ) {
		    if ( !regs[i].used ) { continue; }

		    switch ( regs[i].item ) {
		     case 'v': {
			int size = regs[i].axis[0].size;

			slice_val(&regs[i], regs[i].type, (void *)&regs[i].value);
			for ( j = 0; j < NDIM; j++ ) {
			    regs[i].axis[j].size = size;
			    regs[i].offs[j] = &regs[i].value;
			}

			break;
		     }

		     case 'a': { slice_reg(&regs[i], regs[i].type);	 			break; }
		     case 'i':
		     case 'o':
		     case 'x':
		     case 'c': { slice_val(&regs[i], regs[i].type, (void *)&regs[i].value);	break; }
		     case 't': {
			for ( j = 0; j < NDIM; j++ ) { regs[i].offs[j] = regs[i].data; }
			break;
		     }
		    }
		}
		m[k].registers = regs; 
		m[k].program   = (Instruct *) text;
		m[k].registers = regs;
		m[k].nr        = nregs;
		m[k].zero      = zero[k];
		m[k].dims      = dims[k];
		m[k].nd	       = ndim;

		thr[k] = TPoolThreadStart(tp, (TPoolWork) slice_thr, &m[k]);
	    }

	    slice_thr(&m[0]);

	    for ( k = 0; k < nthread; k++ ) {
		if ( k ) { TPoolThreadWait(thr[k]); }

		regs = m[k].registers;

		for ( i = 0; i < nregs; i++ ) {
		    if ( !regs[i].used ) { continue; }

		    switch ( regs[i].item ) {
		     case 'o':
		     case 'x': {
			if ( !k ) {
			    Tcl_ObjSetVar2(ip, regs[i].name, NULL, Tcl_NewDoubleObj(regs[i].value._double), 0);
			}
			break;
		     }
		     case 'a': { free(regs[i].data);	 			break; }
		    }
		}

		free(m[k].registers);
	    }
	    free(text);
	}

	return TCL_OK;
    }]

    critcl::cproc bytes { Tcl_Interp* ip long data int size } ok {
	//printf("bytes : %p %d\n", data, size);
	Tcl_SetObjResult(ip, Tcl_NewByteArrayObj((void *)data, size));
	//printf("set : %p %d\n", data, size);

	return TCL_OK;
    }

}
