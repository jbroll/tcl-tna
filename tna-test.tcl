#!/usr/bin/env tclkit8.6
#

lappend auto_path lib

package require tna

source expression.tcl

proc timer { op args } {
    	upvar #0 Timer Timer

    if { $args ne {} } {
	set now [expr [clock clicks -milliseconds]/1000.0]

	foreach name $args {
	    if { ![info exists Timer($name)] } { set Timer($name) 0 }

	    switch $op {
		start { set Timer($name,start) $now }
		stop  { 
		    set Timer($name) [expr { $Timer($name) + ($now - $Timer($name,start)) }]
		    unset Timer($name,start)
		}
	    }
	}
	return $Timer($name)
    } else {
	if { [info exists Timer($op,start)] } {
	    set now [expr [clock clicks -milliseconds]/1000.0]

	    return [expr { $Timer($op) + ($now - $Timer($op,start)) }]
	} else {
	    return $Timer($op)
	}
    }
}

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
    ::array set ItemsX { none 0 temp 1 const 2 tna 3 cntr 4 }

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


		if { $s eq {} || $s eq "*" } { set s  0 	   }
		if { $e eq {}              } { set e [::expr $d-1] }
		if { $i eq {}              } { set i  1 	   }

		if { $s < 0 } { set s [::expr $d+$s] }
		if { $e < 0 } { set e [::expr $d+$e] }
	    }

	    lappend list [list $s $e $i]
	}

	return $list
    }

    proc lookup { name regName typName itmName datName } {
	variable regs

	upvar $regName reg
	upvar $typName typ
	upvar $itmName itm
	upvar $datName dat

	if { ![info exists regs($name)] } {
	    register $name $name
	}
	lassign $regs($name) reg typ itm dat
    }

    proc tempreg { type } {
	set reg   [incr ::tna::nreg]
	set name @$reg

	set ::tna::regs($name) [list $reg $type temp $name temp : $::tna::ItemsX(temp) $::tna::TypesX($type) {} {}]

	return $reg
    }
    proc register { name value { type {} } } {
	set dims {}
	set slic {}
	set item const

	if { [info command $name] ne {} } {
	    set data [$name data]
	    set type [$name type]
	    set dims [$name dims]
	    set slic [xindx $dims {}]
	    set item tna
	} elseif { [string is int    $value] } {
	    set type int
	    set data $value
	} elseif { [string is double $value] } {
	    set type double
	    set data $value
	} elseif { $name in { X Y Z T U V } } {
	   set type int
	   set item cntr
	   set data [::expr -([lsearch { X Y Z T U V } $name]+1)]
	} else {
	    error "unknown identifier : $name"
	}

	set ::tna::regs($name) 	\
	    [list [incr ::tna::nreg] $type $item $name $data : $::tna::ItemsX($item) $::tna::TypesX($type) $dims $slic]
	#puts "set regs($name) $::tna::regs($name)"
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
		lappend text [list $::tna::OpcodesX(tna_opcode_${type}_${typeC}) $reg 0 $N]
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

	lookup $name - - - -

	set reg [tempreg int]

	foreach i { 1 2 4 6 7 8 } {
	    lset regs(@$reg) $i [lindex $regs($name) $i]
	}

	lset regs(@$reg) end [xindx [$name dims] $args]

	return @$reg
    }

    proc assign { op a b } {
	variable regs
	variable text
	
	lookup $a regA typeA - -
	lookup $b regB typeB - -

	if { $b eq "X" } {						# Add X register fixup
	    set tmp [tempreg $typeB]
	    lappend text [list $::tna::OpcodesX(tna_opcode_xxx_$typeB) $regB 0 $tmp]
	    set regB $tmp
	}

	# If the types are the same and the target is a tmp register,
	# change the target of the previous instr
	#
	if { $typeA eq $typeB && [info exists regs(@[lindex $text end end])] } {
	    lset text end end $regA						
	} else {
	    lappend text [list $::tna::OpcodesX(tna_opcode_${typeB}_$typeA) $regB 0 $regA]
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

	lookup $a regA typeA itemA dataA
	lookup $b regB typeB itemB dataB

	if { $a eq "X" } {					  # X register fixup
	    if { $::tna::X eq {} } {
		set tmp [tempreg $typeA]
		lappend text [list $OpcodesX(tna_opcode_xxx_$typeA) $regA 0 $tmp]
		set ::tna::X [set regA $tmp]
	    } else {
		set regA $::tna::X
	    }
	}
	if { $b eq "X" } {					  # X register fixup
	    if { $::tna::X eq {} } {
		set tmp [tempreg $typeB]
		lappend text [list $OpcodesX(tna_opcode_xxx_$typeB) $regB 0 $tmp]
		set ::tna::X [set regB $tmp]
	    } else {
		set regB $::tna::X
	    }
	}

	if { $itemA eq "const" && $itemB eq "const" } {		; # Try constant folding
	    set c [::expr "\$dataA $::expression::opers($op) \$dataB"]

	    lookup $c - - - -

	    return $c
	} else {
	    promote C regC typeC $regA $typeA A $regB $typeB B
	    lappend text [list $OpcodesX(tna_opcode_${op}_$typeC) $A $B $regC]

	    return $C
	}
    }

    proc Compile { op args } { return [$op $op {*}$args] }

    proc compile { expr } {
	variable regs
	variable    X {}
	variable text {}
	variable nreg  0

	::array unset regs
	set regs(0) [list 0 0 @0 0 0 : $::tna::ItemsX(const) $::tna::TypesX(int) {} {}]

	expression::parse $expr [expression::prep-tokens $::expression::optable] $::expression::optable ::tna::Compile

	return [list [lsort -real -index 0 [map { name values } [::array get regs] { I $values }]] $text]
    }
    proc expr { expr } {
	set xxx [compile $expr]
	puts [::tna::disassemble {*}$xxx]
	::tna::execute {*}$xxx
    }

    proc mprint { regs text } {
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
	    lassign $r n type item name data : i t dims slice

	    switch $item {
		none -
		temp  { append listing [format " %4d  %-8s %-14s  %8s\n" $n $item $name $type] }
		cntr  { append listing [format " %4d  %-8s %-14s  %8s	%d\n" $n $item $name $type $data] }
		const { append listing [format " %4d  %-8s %-14s  %8s	%f\n" $n $item $name $type $data] }
		tna   { append listing [format " %4d  %-8s %-14s  %8s	0x%08x : %s %s\n" $n $item $name $type $data $dims $slice] }
	    }
	}
	append listing	"#\n"
	append listing	"#\n"

	append listing	"# Text\n"
	append listing	"#\n"
	set n 0
	foreach { instr } $text {
	    lassign $instr I R0 R1 R2

	    append listing [format " %4d  %25s  %10s %10s %10s\n"	\
	    	[incr n] $OpcodesR($I) [lindex $regs $R0 3] [lindex $regs $R1 3] [lindex $regs $R2 3]]
	}

	return $listing
    }

    proc print { x } { xprint [$x data] $::tna::TypesX([$x type]) {*}[$x dims] }
}


#timer start A

#tna::array create a double [expr 1024*1024] 1
#tna::array create b double [expr 1024*1024] 1
#tna::array create c double [expr 1024*1024] 1

tna::array create a double 2048 2048
tna::array create b double 2048 2048
tna::array create c double 2048 2048

#tna::array create J double 1 1

#puts [timer A]

#tna::expr { a   = 1 }
#tna::expr { J  += a }



#tna::print J


#timer start B
#set xxx [::tna::compile { c = a*a + b*b + 2.0 * a * b }]
#puts [timer B]

#puts [::tna::disassemble {*}$xxx]

#timer start B
#::tna::execute {*}$xxx
#puts [timer B]

tna::expr { a = X+Y }
tna::expr { b = 2 }

foreach i [iota 1 100] {
    tna::expr { c = a*a + b*b + 2.0 * a * b }
}

#puts [timer A]
exit



tna::array create A double 6 6
tna::array create B int    4 4
tna::array create C double 3 3 

#tna::expr { C = X*X+X }
#tna::print C

tna::expr { B += D }

tna::print B

exit
tna::expr { C[0,0] = 1 }
tna::expr { C[1,0] = 2 }
tna::expr { C[2,0] = 3 }
tna::expr { C[0,1] = 4 }
tna::expr { C[1,1] = 5 }
tna::expr { C[2,1] = 6 }
tna::expr { C[0,2] = 7 }
tna::expr { C[1,2] = 8 }
tna::expr { C[2,2] = 9 }

tna::expr { C += B + 5 }
tna::expr { A = C }

tna::print [C data] {*}[C dims]
puts ""
tna::print [A data] {*}[A dims]
