
source expression.tcl

oo::class create tna::thing {
    variable type dims data size indxDefault

    set indxDefault XYZ


    method list-helper { bytes dims offs } {

	set d [lindex $dims 0]
		
	if { [llength $dims] == 1 } {
	    for { set i 0 } { $i < $d } { incr i } {
		binary scan $bytes x$offs$::tna::TypesScan($type)[lindex $dims 0] row;
		
		switch $type {
		 uchar  { set row [map value $row { expr { $value &        0xFF } }] }
		 ushort { set row [map value $row { expr { $value &      0xFFFF } }] }
		 uint   { set row [map value $row { expr { $value &  0xFFFFFFFF } }] }
		 ulong  { set row [map value $row { expr { $value &  0xFFFFFFFF } }] }
		}
		
		return $row

	    }    
	} else {

	    for { set i 0 } { $i < $d } { incr i } {
		lappend reply [my list-helper $bytes [lrange $dims 1 end] $offs]

		set sum [::tna::sizeof_$type]
		incr offs [red x [lrange $dims 1 end] { set sum [::expr { $sum*$x }] }]
	    }
	}

	return $reply
    }
    method destroy {} {
	::tna::free $data
	next
    }

    method bytes {} { tna::bytes $data [::expr $size*[tna::sizeof_$type]] }
    method print { { fp stdout } } { puts $fp [my list] }
}
oo::class create tna::array {
    variable type dims data size offs indx indxDefault
    accessor type dims data size offs indx indxDefault

    superclass tna::thing

    constructor { Type args } {
	classvar indxDefault XYZ

	while { [lindex $args 0] ne {} && [string is integer [lindex $args 0]] } {
	    lappend dims [lindex $args 0]
	    set args [lrange $args 1 end]
	}
	array set options [list -offset { 0 } -index $indxDefault]
	array set options $args

	set type $Type
	set size 1
	set offs $options(-offset)
	set indx $options(-index)

	if { [llength $offs] == 1 } {
	    set offs [lrepeat [llength $dims] $options(-offset)]
	} 
	if { [llength $offs] != [llength $dims] } {
	    error "number of offsets and dimensions must match $offs : $dims"
	}

	set data [::tna::malloc_$type [red x $dims { set size [::expr $size*$x] }]]
    }

    method list  {} { return [my list-helper [my bytes] [lreverse $dims] 0] }

    method indx { { xindx {} } } {			  # Parse the slice syntax into a list.

	if { $indx eq "ZYX" } { set xindx [lreverse $xindx] }

	foreach d $dims x $xindx o $offs {
	    if { $d eq {} } { break }

	    set xindx [split $x :]

	    if { [llength $xindx] == 1 && $x != "*" } {
		if { $x < 0 } { set x [::expr { $d + $x }] }
		set s $x
		set e $x
		set i  1
	    } else {
		lassign $xindx s e i

		if { $s eq {} || $s eq "*" } { set s $o 	   }
		if { $e eq {}              } { set e [::expr { $d - 1 + $o }] }
		if { $i eq {}              } { set i  1 	   }

		if { $s < 0 } { set s [::expr { $d + $s }] }
		if { $e < 0 } { set e [::expr { $d + $e }] }
	    }
	    set s [::expr { $s - $o }]
	    set e [::expr { $e - $o }]

	    lappend list [list $s $e $i]
	}

	return $list
    }
}
oo::class create tna::value {
    variable type dims data size offs
    accessor type dims data size offs

    superclass tna::thing

    constructor { Type value } {
	set type $Type
	set dims { 1 }
	set offs { 0 }
	set size 1
	set data  [tna::malloc_$type $size]
    }
    method list  {} { return [my list-helper [my bytes] 1 0] }
    method indx  { args } { return [list [list 0 0 0]] }
}

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
	     float  float		double  %f 	double	Tcl_GetDoubleFromObj	f 
	    double  double		double  %f 	double	Tcl_GetDoubleFromObj	d 
    }

    ::array set ItemsX { none 0 temp 1 const 2 tna 3 cntr 4 }

    set reglist {}


    proc lookup { name regName typName itmName datName { suggestType {} } } {
	variable regs

	upvar $regName reg
	upvar $typName typ
	upvar $itmName itm
	upvar $datName dat

	if { ![info exists regs($name)] && ![info exists regs($name-$suggestType)] } {
	    register $name $name $suggestType
	}

	if { [info exists regs($name)] } {
	    lassign $regs($name) reg typ itm dat
	} else {
	    lassign $regs($name-$suggestType) reg typ itm dat
	}

    }

    proc tempreg { type { regtype temp } } {
	if { [llength $::tna::reglist] == 0 } {
	    set reg   [incr ::tna::nreg]
	    set name @$reg
	} else {
	    set name [lindex $::tna::reglist end]
	    set ::tna::reglist [lrange $::tna::reglist 0 end-1]
	    set reg [string range $name 1 end]
	}

	set ::tna::regs($name) [list $reg $type $regtype $name $regtype : $::tna::ItemsX(temp) $::tna::TypesX($type) {} {}]

	return $reg
    }
    proc dispose { name } {
	if { [string index $name 0] eq "@" && [lindex $::tna::regs($name) 2] eq "temp" } {
	    lappend ::tna::reglist $name
	}
    }
    proc register { name value { type {} } } {
	set dims {}
	set slic {}
	set item const

	if { [info command $name] ne {} } {
	    set data [$name data]
	    set type [$name type]
	    set dims [$name dims]

	    set slic [$name indx]
	    set item tna
	} elseif { [string is int    $value] } {
	    set data $value
	    if { $type eq {} } {
		set type int
	    } else {
		set name $name-$type
	    }
	} elseif { [string is double $value] } {
	    set data $value
	    if { $type eq {} } {
		set type double
	    } else {
		set name $name-$type
	    }
	} elseif { $name in $::tna::Axes } {
	   set type int
	   set item cntr
	   set data [::expr -([lsearch $::tna::Axes $name]+1)]
	} else {
	    error "unknown identifier : $name"
	}

	set ::tna::regs($name) 	\
	    [list [incr ::tna::nreg] $type $item $name $data : $::tna::ItemsX($item) $::tna::TypesX($type) $dims $slic]
    }
    proc register-type { name } { return [lindex ::tna::regs($name) 1] }


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
		dispose $reg
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

	lset regs(@$reg) end [$name indx $args]

	return @$reg
    }

    proc suggest { a b } {
	if { [string is int $a] || [string is double $a]
	  || [string is int $a] || [string is double $a]

	    if       { [info command $a] ne {} } 	{ return [$a type]
	    } elseif { [info command $b] ne {} } 	{ return [$b type]
	    } elseif { [string $a index 0] eq "@" }	{ return [register-type $a]
	    } elseif { [string $b index 0] eq "@" }	{ return [register-type $b]
	    } else   {                                    return {} }

	}
    }

    proc assign { op a b } {
	variable regs
	variable text
	
	lookup $a regA typeA - -
	lookup $b regB typeB - -

	if { $typeA == "any" } { set typeA $typeB }
	if { $typeB == "any" } { set typeB $typeA }

	if { $b eq "X" } {						# Add X register fixup
	    set tmp [tempreg $typeB cx]
	    lappend text [list $::tna::OpcodesX(tna_opcode_xxx_$typeB) $regB 0 $tmp]
	    set ::tna::X [set regB $tmp]
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

    interp alias {} ::tna::inc  {} ::tna::uniop
    interp alias {} ::tna::dec  {} ::tna::uniop
    interp alias {} ::tna::uinc {} ::tna::uniop
    interp alias {} ::tna::udec {} ::tna::uniop
    interp alias {} ::tna::usub {} ::tna::uniop
    interp alias {} ::tna::uadd {} ::tna::uniop

    proc uniop { op a } {
	variable text

	lookup $a regA typeA itemA dataA

	switch $op {
	 dec - udec { set incr -1 }
	 inc - uinc { set incr  1 }
	}

	set tmp [tempreg $typeA]

	switch -- $op {
	 inc - dec {
	    lookup  $incr reg1 type1 -     - $typeA

	    lappend text [list $::tna::OpcodesX(tna_opcode_${typeA}_${typeA}) $regA     0 $tmp]
	    lappend text [list $::tna::OpcodesX(tna_opcode_add_${typeA})      $regA $reg1 $regA]

	    return @$tmp
	 }
	 uinc - udec {
	    lookup  $incr reg1 type1 -     - $typeA

	    lappend text [list $::tna::OpcodesX(tna_opcode_add_${typeA})      $regA $reg1 $regA]

	    return $a
	 }
	 uadd { return $a }
	 usub { binop $op $a 0 }
	}
    }

    interp alias {} ::tna::add  {} ::tna::binop
    interp alias {} ::tna::sub  {} ::tna::binop
    interp alias {} ::tna::mul  {} ::tna::binop
    interp alias {} ::tna::div  {} ::tna::binop
    interp alias {} ::tna::mod  {} ::tna::binop
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

	lookup $a regA typeA itemA dataA
	lookup $b regB typeB itemB dataB

	if { $typeA == "any" } { set typeA $typeB }
	if { $typeB == "any" } { set typeB $typeA }

	if { $a eq "X" } {					  # X register fixup
	    if { $::tna::X eq {} } {
		set tmp [tempreg $typeA cx]
		lappend text [list $::tna::OpcodesX(tna_opcode_xxx_$typeA) $regA 0 $tmp]
		set ::tna::X [set regA $tmp]
	    } else {
		set regA $::tna::X
	    }
	}
	if { $b eq "X" } {					  # X register fixup
	    if { $::tna::X eq {} } {
		set tmp [tempreg $typeB cx]
		lappend text [list $::tna::OpcodesX(tna_opcode_xxx_$typeB) $regB 0 $tmp]
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
	    dispose $a
	    dispose $b
	    lappend text [list $::tna::OpcodesX(tna_opcode_${op}_$typeC) $A $B $regC]

	    return $C
	}
    }

    proc Compile { op args } { return [$op $op {*}$args] }

    proc semi { op } {
	exprSave
	exprStart
    }

    proc exprStart {} {
	variable regs
	variable    X {}
	variable text {}
	variable nreg  0
	variable reglist {}

	::array unset regs
	set regs(0) [list 0 any @0 0 0 : $::tna::ItemsX(const) $::tna::TypesX(int) {} {}]
    }
    proc exprSave {} {
	variable Code
	variable regs
	variable text

	if { $text ne {} } {
	    lappend Code [list [lsort -real -index 0 [map { name values } [::array get regs] { I $values }]] $text]
	}

	exprStart
    }

    proc compile { expr } {
	variable Code {}

	exprStart
	expression::parse $expr [expression::prep-tokens $::expression::optable] $::expression::optable ::tna::Compile
	exprSave

	return $Code
    }
    proc expr { expr } {
	set code [compile $expr]
	if { $::tna::debug } { puts [::tna::disassemble {*}$code] }
	foreach stmt $code {
	    ::tna::execute {*}$stmt
	}
    }
    proc debug { x } { set ::tna::debug $x }

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
		cx    -
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
}
