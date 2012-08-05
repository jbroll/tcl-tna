#!/usr/bin/env tclkit8.6
#

lappend auto_path lib

package require tna

source expression.tcl

oo::class create tna::array {
    variable type dims data
    accessor type dims data

    constructor { Type args } {
	set type $Type
	set dims $args

	set bytes 1
	set data [::tna::malloc_$type [red x $args { set bytes [::expr $bytes*$x] }]]
    }
}
oo::class create tna::value {
    variable type dims data value
    accessor type dims data value

    constructor { Type args } {
	set type $Type
	set dims { 0 0 0 0 0 }

	set value [lindex $args 0]
	set data  [tna::malloc_$type 1]
    }
}

namespace eval tna {
    set text {}

    proc xindx { dims indx } {			  # Parse the slice syntax into a list.
	foreach d $dims x $indx {
	    if { $d eq {} } { break }

	    set indx [split $x :]

	    if { [llength $indx] == 1 && $x != "*" } {
		if { $x < 0 } { set x [::expr $d+$x] }
		set s $x
		set e $x
		set i  1
	    } else {
		lassign $indx s e i


		if { $s eq {} || $s eq "*" } { set s  0 	      }
		if { $e eq {}              } { set e [::expr $d-1]  }
		if { $i eq {}              } { set i  1 	      }

		if { $s < 0 } { set s [::expr $d+$s] }
		if { $e < 0 } { set e [::expr $d+$e] }
	    }

	    lappend list [list $s $e $i]
	}

	return $list
    }

    proc lookup { name regName typName objName numName datName dimName } {
	variable regs

	upvar $regName reg
	upvar $typName typ
	upvar $objName obj
	upvar $numName num
	upvar $datName dat
	upvar $dimName dim

	if { ![info exists regs($name)] } {
	    register $name $name
	}
	lassign $regs($name) reg typ obj num dat dim
    }

    proc tempreg { type { value {} } } {
	variable regs
	variable nreg

	set reg   $nreg
	set name @$nreg
	set data $value


	set regs($name) [list $nreg $type $name $data * {}]
	incr nreg

	return $reg
    }
    proc register { name value { type {} } } {
	variable TypesX

	variable nreg
	variable regs

	set dims {}
	set slic {}

	if { [info command $name] ne {} } {
	    set data [$name data]
	    set type [$name type]
	    set dims [$name dims]
	    set slic [xindx $dims {}]
	} elseif { [string is int    $value] } {
	    set type int
	    set data $value
	} elseif { [string is double $value] } {
	    set type double
	    set data $value
	} else {
	    error "unknown identifier : $name"
	}

	set regs($name) [list $nreg $type $name $TypesX($type) $data $dims $slic]
	incr nreg
    }


    proc promote { c regc typec args } {
	variable OpcodesX
	variable text

	upvar $c C
	upvar $regc regC
	upvar $typec typeC

	set typeC none
	foreach { reg type Name } $args {
	    set typeC [lindex $tna::Types [::expr max([lsearch $::tna::Types $typeC], [lsearch $::tna::Types $type])]]
	}

	foreach { reg type Name } $args {
	    upvar $Name N

	    if { $type ne $typeC } {
		set N [tempreg $typeC]
		lappend text $OpcodesX(tna_opcode_${type}_${typeC}) $reg 0 $N
	    } else {
		set N $reg
	    }
	}

	set regC [tempreg $typeC]
	set C @$regC
    }

    proc indx  { op name args } {
	variable regs

	if { [info commands $name] eq {} } {
	    error "only an array can be indexed"
	}

	lookup $name - - - - - -

	set reg [tempreg {}]
	set regs($reg) $regs($name)

	lset regs($reg) end [xindx [$name dims] $args]

	return $reg
    }

    proc assign { op a b } {
	variable OpcodesX
	variable regs
	variable text
	
	lookup $a regA typeA - - - -
	lookup $b regB typeB - - - -

	# If the types are the same and the target is a tmp register,
	# change the target of the previous instr
	#
	if { $typeA eq $typeB && [info exists regs(@[lindex $text end])] } {
	    lset text end $regA						
	} else {
	    lappend text $OpcodesX(tna_opcode_${typeB}_$typeA) $regB 0 $regA
	}

	return $a
    }


    interp alias {} ::tna::addasn {} ::tna::asnop
    interp alias {} ::tna::subasn {} ::tna::asnop
    interp alias {} ::tna::mulasn {} ::tna::asnop
    interp alias {} ::tna::divasn {} ::tna::asnop
    interp alias {} ::tna::modasn {} ::tna::asnop
    interp alias {} ::tna::bndasn {} ::tna::asnop
    interp alias {} ::tna::bxrasn {} ::tna::asnop
    interp alias {} ::tna::borasn {} ::tna::asnop
    interp alias {} ::tna::shrasn {} ::tna::asnop
    interp alias {} ::tna::shlasn {} ::tna::asnop

    proc asnop { op a b } {
	assign $op $a [binop [string range $op  0 2] $a $b]
    }

    interp alias {} ::tna::add  {} ::tna::binop
    interp alias {} ::tna::sub  {} ::tna::binop
    interp alias {} ::tna::mul  {} ::tna::binop
    interp alias {} ::tna::div  {} ::tna::binop
    interp alias {} ::tna::shr  {} ::tna::binop
    interp alias {} ::tna::shl  {} ::tna::binop
    interp alias {} ::tna::gt   {} ::tna::binop 
    interp alias {} ::tna::lt   {} ::tna::binop
    interp alias {} ::tna::lte  {} ::tna::binop
    interp alias {} ::tna::gte  {} ::tna::binop
    interp alias {} ::tna::equ  {} ::tna::binop
    interp alias {} ::tna::neq  {} ::tna::binop
    interp alias {} ::tna::band {} ::tna::binop
    interp alias {} ::tna::bxor {} ::tna::binop
    interp alias {} ::tna::bor  {} ::tna::binop
    interp alias {} ::tna::land {} ::tna::binop
    interp alias {} ::tna::lor  {} ::tna::binop
    interp alias {} ::tna::equ  {} ::tna::binop
    interp alias {} ::tna::neq  {} ::tna::binop

    proc binop { op a b } {
	variable OpcodesX
	variable text

	lookup $a regA typeA nameA - dataA dimsA
	lookup $b regB typeB nameB - dataB dimsB

	if { $dimsA eq {} && $dimsB eq {} } {		; # Try constant folding
	    set c [::expr "\$dataA $::expression::opers($op) \$dataB"]

	    lookup $c nameC - - - - -

	    return $c
	} else {

	    # If one of the operands is a value its register should be promoted
	    # to the type of the other operand.  Copy to a new register.


	    promote C regC typeC $regA $typeA A $regB $typeB B
	    lappend text $OpcodesX(tna_opcode_${op}_$typeC) $A $B $regC

	    return $C
	}
    }

    proc Compile { op args } { return [$op $op {*}$args] }

    proc compile { expr } {
	variable regs
	variable nreg  1
	variable text {}

	::array unset regs
	set regs(0) {0 any 0 0 {} {} }

	expression::parse $expr [expression::prep-tokens $::expression::optable] $::expression::optable ::tna::Compile

	return [list [lsort -real -index 0 [map { name values } [::array get regs] { I $values }]] $text]
    }
    proc expr { expr } {
	::tna::execute {*}[compile $expr]
    }

    proc print { regs text } {
	puts [join $regs \n]
	puts ""
	puts [join [map { i r1 r2 r3 } $text { list $i $r1 $r2 $r3 }] \n]
	puts ""
    }
    proc disassemble { regs text } {
	variable TypesX
	variable TypesR

	variable OpcodesX
	variable OpcodesR

	if { ![info exists OpcodesR] } {
	    foreach { name op } [::array get OpcodesX] {
		set OpcodesR($op) $name
	    }
	}
	if { ![info exists OpcodesR] } {
	    foreach { name op } [::array get OpcodesX] {
		set OpcodesR($op) $name
	    }
	}
	if { ![info exists TypesR] } {
	    set i 0
	    foreach { name n } [::array get TypesX] {
		set TypesR($n)  $name
	    }
	}

	append listing 	"# TNA Disassembly Listing\n"
	append listing	"#\n"
	append listing	"#\n"
	append listing	"# Registers\n"
	append listing	"#\n"

	foreach r $regs {
	    lassign $r n type name data dims slice

	    append listing [format " %4d  %-14s  %8s\n" $n $name $type]
	}
	append listing	"#\n"
	append listing	"#\n"

	append listing	"# Text\n"
	append listing	"#\n"
	set n 0
	foreach { I R0 R1 R2 } $text {
	    append listing [format " %4d  %25s  %10s %10s %10s\n"	\
	    	[incr n] $OpcodesR($I) [lindex $regs $R0 2] [lindex $regs $R1 2] [lindex $regs $R2 2]]
	}

	return $listing
    }
}

tna::array create A double 3 3 
tna::array create B int    3 3
tna::array create C double 3 3 

#tna::print {*}[tna::compile { A[1,1] = B }]
#exit


set expr { C = A -= B * (4 + 6.0) }
puts [tna::disassemble {*}[tna::compile $expr]]
tna::print {*}[tna::compile $expr]
tna::execute {*}[tna::compile $expr]

#tna::expr $expr

