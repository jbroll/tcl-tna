#!/home/john/bin/tclkit8.6
#

lappend auto_path lib

package require tnaplus

source tcloo.tcl
source tna-util.tcl


namespace eval tna {}
set ::tna::regsize 1024

proc tna::pregs { regs } {
    upvar $regs R

    foreach { name value } [lsort -stride 2 -index 1 [::array get R]] {
	puts "$name\t$value"
    }
}
proc tna::ptext { text } {
    foreach line $text {
	lassign $line op r1 r2 r3

	puts "[format %15s $op] [format %3d $r1] [format %3d $r2] [format %3d $r3]"
    }
}

oo::class create tna::array {
    variable type dims data
    accessor type dims data

    constructor { Type args } {
	set type $Type
	set dims $args

	set bytes 1
	set data [::tna::malloc_$type [red x $args { set bytes [expr $bytes*$x] }]]
    }
}
oo::class create tna::value {
    variable type dims data
    accessor type dims data

    constructor { Type args } {
	set type $Type
	set dims { 0 0 0 0 0 }

	set data [tna::malloc-$type 1]
    }
}

# Tcl Numeric Array assembler
#
# Opcodes of the TNA machine are written in 3 address notation.  The assignment arrow reminds
# everyone what the argument order is.  Otherwise it is syntacic sugar.  The second argument
# to unary operators is ignored.  
#
# Arguments to opcodes must be declaried registers.  Registers may be decalired to contain
# arrays, values, constants or then can be temporaries.  The expected types of registers must
# match thier instructions.
#
#  opcode is one of the recognized operators:
#
#	set
#	add sub mul div mod neg
#	equ neq gt lt gte lte
#	and or band borr bxor shl shr
#	exp pow sin cos tan atan
#
# Index registers:
#
# There are 5 special registers used to access the current slice index.  They are
# named X, Y, Z, U, and V.  The X register may only be used with the special xxx instruction
# to copy the X index vector to a temporary.  The other index registers are scaler values and
# may be used as any other scalers are.
#
# 
# Example:
#

oo::class create tna::machine {
    variable text registers nreg

    constructor { code } {
	set nreg 5


	      # reg type name value dims
	      #
	array set registers {
	    X { 0   uint X    {}    {} }
	    Y { 1   uint Y    {}    {} }
	    Z { 2   uint Z    {}    {} }
	    U { 3   uint U    {}    {} }
	    V { 4   uint V    {}    {} } }

	procs set xxx register

	foreach op [list mod band bor bxor bnot add sub mul div \
		     neg equ neq gt lt gte lte		    \
		     cos sin tan acos asin			    \
		     atan atan2				    \
		     exp log log10 pow sqrt			    \
		     ceil abs floor] {
	    proc $op { args } "my opcode $op {*}\$args"
	}
	eval $code


	puts ""
	::tna::pregs registers
	puts ""
	::tna::ptext $text
	puts ""
    }


    method reg-lookup { r regName typName } {
	upvar $regName reg
	upvar $typName typ

	lassign $registers($r) reg typ
    }

    method register { name value { type {} } } {
	::set dims { 0 0 0 0 0 }

	if { $value eq "*" } {
	    ::set slice {}
	    ::set data  [tna::malloc_$type $::tna::regsize]
	} elseif { [string is double $value] } {
	    ::set slice {}
	    ::set data $value
	} else {
	    ::set name  unknown
	    ::set slice {}
	    regexp {([a-zA-Z][0-9a-zA-Z]*)(\(([^)]+)\))?} $value -> name slice

	    ::set type  [$name type]
	    ::set data  [$name data]
	    ::set slice [tna::indx [$name dims] $slice]
	}

	::set registers($name) [list [incr nreg] $type $name $data $slice]
    }

    method set { r1 -> r2 } {
	my reg-lookup $r1 r1n type1
	my reg-lookup $r2 r2n type2

	lappend text [list ${type1}2${type2} $r1n 0 $r2n]
    }
    method xxx { r1 -> r2 } {
	my reg-lookup $r1 r1n type1
	my reg-lookup $r2 r2n type2

	if { $r1 ne "X" } { error "xxx source must be X" }

	lappend text [list xxx_$type2 $r1n 0 $r2n]
    }

    method opcode { op r1 r2 -> r3 } {
	my reg-lookup $r1 r1n type1
	my reg-lookup $r2 r2n type2
	my reg-lookup $r3 r3n type3

	if { $type1 ne $type3 } { 
	    ::tna::pregs registers
	    error "opcode $op : type mismatch $r1 ($type1) ne $r3 ($type3)"
	}
	if { $type2 ne $type3 } {
	    ::tna::pregs registers
	    error "opcode $op : type mismatch $r2 ($type2) ne $r3 ($type3)"
	}

	lappend text [list ${op}_$type1 $r1n $r2n $r3n]
    }
}

    tna::array create A float 1024 1024
    tna::array create B float 1024 1024

    tna::machine create X {
	register A  A
	register B  B
	register 4  4 float
	register T1 * float
	register T2 * uint
	register T3 * float

	add A   4  -> T1	; # B = A+4 + X*Y
	xxx X      -> T2
	mul T2  Y  -> T2
	set T3     -> T3
	add T3  T1 -> B
    }

