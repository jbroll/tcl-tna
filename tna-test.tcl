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
	foreach d $dims x [split $indx ,] {
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

    proc lookup { name regName typName objName datName dimName } {
	variable regs

	upvar $regName reg
	upvar $typName typ
	upvar $objName obj
	upvar $datName dat
	upvar $dimName dim

	if { ![info exists regs($name)] } {
	    register $name $name
	}
	lassign $regs($name) reg typ obj dat dim
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
	variable nreg
	variable regs

	if { [info command $name] ne {} } {
	    set data [$name data]
	    set type [$name type]
	    set dims [$name dims]
	} elseif { [string is int    $value] } {
	    set type int
	    set data $value
	    set dims {}
	} elseif { [string is double $value] } {
	    set type double
	    set data $value
	    set dims {}
	} else {
	    error "unknown identifier : $name"
	}

	set regs($name) [list $nreg $type $name $data $dims {}]
	incr nreg
    }


    proc promote { c regc typec args } {
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
		lappend text [list tna_opcode_${type}_${typeC} $reg 0 $N] 
	    } else {
		set N $reg
	    }
	}

	set regC [tempreg $typeC]
	set C @$regC
    }

    proc indx  { op args } {
	puts "$op $args"
    }

    proc assign { op a b } {
	variable regs
	variable text
	
	lookup $a regA typeA - dataA dimsA
	lookup $b regB typeB - dataB dimsB

	# If the types are the same and the target is a tmp register,
	# change the target of the previous instr
	#
	if { $typeA eq $typeB && [info exists regs(@[lindex $text end end])] } {
	    lset text end end $regA						
	} else {
	    lappend text [list tna_opcode_${typeB}_$typeA $regB 0 $regA]
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
	variable text

	lookup $a regA typeA nameA dataA dimsA
	lookup $b regB typeB nameB dataB dimsB

	if { $dimsA eq {} && $dimsB eq {} } {		; # Try constant folding
	    set c [::expr "\$dataA $::expression::opers($op) \$dataB"]

	    lookup $c nameC - - - -

	    return $c
	} else {
	    promote C regC typeC $regA $typeA A $regB $typeB B
	    lappend text [list tna_opcode_${op}_$typeC $A $B $regC]

	    return $C
	}
    }

    proc compile { op args } { return [$op $op {*}$args] }

    proc expr { expr } {
	puts $expr
	puts ""

	variable regs
	variable nreg  1
	variable text {}

	::array unset regs

	expression::parse $expr [expression::prep-tokens $::expression::optable] $::expression::optable ::tna::compile
	::tna::execute [::array get regs] $text
    }

    proc execute { regs text } {
	variable OpcodesX

	puts [join [map { name value } [lsort -real -index {1 0} -stride 2 $regs] { list [format %10s $name] {*}$value }] \n]
	puts ""
	puts [join $text \n]
	puts ""


	set code {}
	foreach instr $text {
	     lappend code [list $OpcodesX([lindex $instr 0]) {*}[lrange $instr 1 end]]
	}
	puts [join $code \n]
	puts ""

	set code {}
	foreach instr $text {
	     append code [binary format s* [list $OpcodesX([lindex $instr 0]) {*}[lrange $instr 1 end]]]
	}

	puts [string length $code]
	binary scan $code s* disass
	puts $disass
    }
}

tna::array create A double 3 3 
tna::array create B int    3 3
tna::array create C double 3 3 

tna::expr { C[1,1] = A -= B * (4 + 6.0) }

