
source types.tcl
source template.tcl


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
	    foreach { name code } $::Opcodes {
		set T $type

		if { $name in $::IntOnly && $type in { float double } } { continue }
		if { $name eq "xxx" } { set T int }

		lappend opcodes $name $T $type $code
	    }

	    foreach { type2 CType pType   pFmt    getType getFunc scan } $::tna::Types {
		lappend opcodes $type $type $type2 { R3 = R1 }
	    }
	}

	return $opcodes
    }

    puts {
#include "tna.h"

#define abs(x)	(x < 0 ? -(x) : (x))

#define R1 *addr1
#define R2 *addr2
#define R3 *addr3

#define INCR		\
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
}

    puts [subst {
	[: { name type type2 code } [opcodes] {
		INSTR(tna_opcode_${name}_${type2}, $type, $type, $type2, $code)
	}]

	OpTable OpCodes\[] = {
	    { NULL, "nop" }
	    [: { name type type2 code } [opcodes] {	, { tna_opcode_${name}_${type2}, "tna_opcode_${name}_${type2}" }\n}]
	};

	int OpCodesN = sizeof(OpCodes)/sizeof(OpCodes\[0]);
    }]

