
source expression.tcl

oo::class create tna::thing {
    variable type dims data drep size indxDefault

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
		 ulong  {
		    if { [::tna::sizeof_long] == 4 } {
			set row [map value $row { expr { $value &          0xFFFFFFFF } }]
		    } else {
			set row [map value $row { expr { $value &  0xFFFFFFFFFFFFFFFF } }]
		    }
		 }
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
	if { $drep eq "ptr" } {
	    ::tna::free $data
	}
	next
    }

    method bytes {} { tna::bytes $data [::expr $size*[tna::sizeof_$type]] }
    method print { { fp stdout } } { puts $fp [my list] }
}

oo::class create tna::array {
    superclass tna::thing

    variable type dims data size drep offs indx edge indxDefault edgeDefault offsDefault
    accessor type dims data size drep offs indx

    constructor { Type args } {
	classvar indxDefault XYZ
	classvar edgeDefault incl
	classvar offsDefault 1

	while { [lindex $args 0] ne {} && [string is integer [lindex $args 0]] } {
	    lappend dims [lindex $args 0]
	    set args [lrange $args 1 end]
	}
	array set options [list -index $indxDefault -edge $edgeDefault -offset $offsDefault -data {} -ptr 0]
	array set options $args

	set type $Type
	set offs $options(-offset)
	set indx $options(-index)
	set edge $options(-edge)

	set data $options(-data)
	set ptr  $options(-ptr)

	if { $edge eq "excl" } { set edge 1
	} else                 { set edge 0 }

	if { [llength $offs] == 1 } {
	    set offs [lrepeat [llength $dims] $options(-offset)]
	} 
	if { [llength $offs] != [llength $dims] } {
	    error "number of offsets and dimensions must match $offs : $dims"
	}

	if { $ptr == 1 } {
	    set drep ptr
	    set size 1
	    set data [::tna::malloc_$type [red x $dims { set size [::expr $size*$x] }]]
	} else {
	    if { $ptr != 0 } {
		set drep  ptr
		set data $ptr
	    } else {
		set drep bytes
		if { $data eq {} } {
		    set size [::tna::sizeof_$type]
		    set data [binary format x[red x $dims { set size [::expr $size*$x] }]]
		}
	    }
	}

    }

    method list  {} { 
	if { $drep eq "ptr" } {
	    return [my list-helper [my bytes] [lreverse $dims] 0]
	} else {
	    return [my list-helper $data      [lreverse $dims] 0]
	}
    }

    method indx { { XIndx {} } } {			  # Parse the slice syntax into a list.
	try {
	    if { $indx eq "ZYX" } { set XIndx [lreverse $XIndx] }

	    if { [llength $XIndx] && [llength $XIndx] != [llength $dims] } {
		error "array has [llength $dims] dims : [llength $XIndx] given"
	    }

	    foreach d $dims x $XIndx o $offs {
		if { $d eq {} } { break }

		set xindx [split $x :]

		if { $x == "*" || $x == ":" } {
		    set s 0
		    set e [::expr { $d - 1 }]
		    set i 1
		} elseif { $x == "-*" } {
		    set s [::expr { $d - 1 }]
		    set e 0
		    set i 1
		} else {
		    if { [llength $xindx] == 1 } {
			set s $xindx

			if { $s < 0 } { set s [::expr { $d + $s }] }

			set e $s
			set i 1
		    } else {
			set e {}
			set i {}

			lassign $xindx s e i

			if { $s eq {} } { set s $o 	   }
			if { $e eq {} } { set e [::expr { $d - 1 + $o + $edge }] }
			if { $i eq {} } { set i  1 	   }

			if { $s < 0 } { set s [::expr { $d + $s }] }
			if { $e < 0 } { set e [::expr { $d + $e + $edge }] }

			set s [::expr { $s - $o }]
			set e [::expr { $e - $o - $edge }]
		    }
		}

		lappend list [list $s $e $i]
	    }

	} on error message {
	    puts $::errorInfo
	    error "cannot convert $xindx to indx : $message"
	}
	return $list
    }
}
oo::objdefine tna::array export varname

oo::class create tna::value {
    variable type dims data size drep offs
    accessor type dims data size drep offs

    superclass tna::thing

    constructor { Type value } {
	set type $Type
	set dims { 1 }
	set offs { 0 }
	set size 1
	set data [tna::malloc_$type $size]
	set drep ptr
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
	     ulong "unsigned long"	long   %lu 	long	Tcl_GetLongFromObj	i
	     float  float		double  %f 	double	Tcl_GetDoubleFromObj	f 
	    double  double		double  %f 	double	Tcl_GetDoubleFromObj	d 
    }

    set reglist {}

    proc index { mode } {
	switch $mode {
	 IRAF {
	    set [tna::array varname indxDefault] XYZ
	    set [tna::array varname offsDefault] 1
	    set [tna::array varname edgeDefault] incl
	 }
	 python {
	    set [tna::array varname indxDefault] ZYX
	    set [tna::array varname offsDefault] 0
	    set [tna::array varname edgeDefault] excl
	 }
	}
    }

    proc lookup { name regName typName itmName datName { suggestType {} } { suggestItem {} } } {
	variable regs

	upvar $regName reg
	upvar $typName typ
	upvar $itmName itm
	upvar $datName dat

	if { ![info exists regs($name)] && ![info exists regs($name-$suggestType)] } {
	    register $name $name $suggestType $suggestItem
	}

	if { [info exists regs($name)] } {
	    lassign $regs($name) reg typ itm dat
	} else {
	    lassign $regs($name-$suggestType) reg typ itm dat
	}
    }

    proc anonreg { type { regtype anon } } {		# Allocate a anon register
	if { [llength $::tna::reglist] == 0 } {
	    set reg   [incr ::tna::nreg]
	    set name @$reg
	} else {
	    set name [lindex $::tna::reglist end]
	    set ::tna::reglist [lrange $::tna::reglist 0 end-1]
	    set reg [string range $name 1 end]
	}

	set ::tna::regs($name) [list $reg $type $regtype $name : anon $regtype {} $::tna::TypesX($type) {} {}]

	return $reg
    }
    proc dispose { name } {				# Push anon register on list for reuse
	if { [string index $name 0] eq "@"	\
	  && [lindex $::tna::regs($name) 2] eq "anon" } {
	    lappend ::tna::reglist $name
	}
    }
    proc register { name value { type {} } { item {} } } {		# Allocate a register for a value of some type
	set dims {}
	set slic {}

	if { [info command $name] ne {} } {
	    set item tna
	    set data [$name data]
	    set drep [$name drep]
	    set type [$name type]
	    set dims [$name dims]

	    set slic [$name indx]
	} elseif { [string is int    $value] } {
	    set item const
	    set data $value
	    set drep  value
	    if { $type eq {} } {
		set type int
	    } else {
		set name $name-$type
	    }
	} elseif { [string is double $value] } {
	    set item const
	    set data $value
	    set drep  value
	    if { $type eq {} } {
		set type double
	    } else {
		set name $name-$type
	    }
	} elseif { $name in $::tna::Axes } {
	    set item const
	    set type int
	    set item vect
	    set data [::expr -([lsearch $::tna::Axes $name]+1)]
	    set drep  vect
	} else {
	    if { $item ne {} } {
		set item $item
		set data $name
		set drep value
		set type double
	    } else {
		error "cannot identify item : $name"
	    }
	}

	try { set typex $::tna::TypesX($type) 
	} on error message { set typex 0 }

	
	set ::tna::regs($name) 	\
	    [list [incr ::tna::nreg] $type $item $name : $drep $data {} $typex $dims $slic]
    }
    proc register-type { name } { return [lindex ::tna::regs($name) 1] }


    proc promote { c regc typec args } {		# Promote args to common widest type, emit conversion code
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
		set N [anonreg $typeC]
		lappend text [list $::tna::OpcodesX(tna_opcode_${type}_${typeC}) $reg 0 $N]
		dispose $reg
	    } else {
		set N $reg
	    }
	}

	set regC [anonreg $typeC]
	set C @$regC
    }

    proc indx  { op name args } {			# bracket operator
	variable regs

	register $name $name

	if { [info commands $name] eq {} } {
	    error "only an array can be indexed"
	}

	lookup $name - - - -

	set reg [anonreg int]

	foreach i { 1 2 5 6 7 8 9 10 } {
	    lset regs(@$reg) $i [lindex $regs($name) $i]
	}

	lset regs(@$reg) end [$name indx $args]

	return @$reg
    }

    proc suggest { a b } {				# Suggest a type
	if { [string is int $a] || [string is double $a]
	  || [string is int $a] || [string is double $a]

	    if       { [info command $a] ne {} } 	{ return [$a type]
	    } elseif { [info command $b] ne {} } 	{ return [$b type]
	    } elseif { [string $a index 0] eq "@" }	{ return [register-type $a]
	    } elseif { [string $b index 0] eq "@" }	{ return [register-type $b]
	    } else   {                                    return {} }

	}
    }

    proc deref { args } { return * }
    proc dolar { op name } {				# Create a ivar (input) register
	if { [info exists ::tna::regs($name)] } {
	    switch [lindex $::tna::regs($name) 2] {
	     ivar - xvar {}
	     ovar { lset ::tna::regs($name)] 2 xvar }
	     default {
		 error "existing value is not a tcl reference : $name"
	     }
	    }

	    return $name
	}
	     
	set ::tna::regs($name) 	\
	    [list [incr ::tna::nreg] double ivar $name : value $name {} $::tna::TypesX(double) {} {}]

	return $name
    }

    proc assign { op a b } {				# Emit code for assignment
	variable regs
	variable text
	
	lookup $a regA typeA itemA - {} ovar
	lookup $b regB typeB -     -

	if { $typeA == "any" } { set typeA $typeB }
	if { $typeB == "any" } { set typeB $typeA }

	if { $b eq "X" } {						# Add X register fixup
	    set tmp [anonreg $typeB anox]
	    lappend text [list $::tna::OpcodesX(tna_opcode_xxx_$typeB) $regB 0 $tmp]
	    set ::tna::X [set regB $tmp]
	    set regB $tmp
	}
	if { $itemA eq "ivar" } {					# Fix up ivar (input) to be xvar
	    lset ::tna::regs($a) 2 xvar
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
	lookup $a - - - - {} xvar

	assign $op $a [binop [string range $op  0 2] $a $b]
    }

    interp alias {} ::tna::inc  {} ::tna::uniop
    interp alias {} ::tna::dec  {} ::tna::uniop
    interp alias {} ::tna::uinc {} ::tna::uniop
    interp alias {} ::tna::udec {} ::tna::uniop
    interp alias {} ::tna::uadd {} ::tna::uniop

    proc uniop { op a } {				# Emit code for unary operators
	variable text

	lookup $a regA typeA itemA -

	switch $op {
	 dec - udec { set incr -1 }
	 inc - uinc { set incr  1 }
	}

	set tmp [anonreg $typeA]

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
    proc usub { op a } {
	if { $a eq "*" } { return "-*" }

	tailcall uniop $op $a
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

    proc binop { op a b } {				# Emit code for binary operators
	variable text

	lookup $a regA typeA itemA dataA
	lookup $b regB typeB itemB dataB

	if { $typeA == "any" } { set typeA $typeB }
	if { $typeB == "any" } { set typeB $typeA }

	if { $a eq "X" } {					  # X register fixup
	    if { $::tna::X eq {} } {
		set tmp [anonreg $typeA anox]
		lappend text [list $::tna::OpcodesX(tna_opcode_xxx_$typeA) $regA 0 $tmp]
		set ::tna::X [set regA $tmp]
	    } else {
		set regA $::tna::X
	    }
	}
	if { $b eq "X" } {					  # X register fixup
	    if { $::tna::X eq {} } {
		set tmp [anonreg $typeB anox]
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

    proc Emit { op args } { return [$op $op {*}$args] }

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
	set regs(0) [list 0 any const 0 : 0 0 {} $::tna::TypesX(int) {} {}]
    }
    proc exprSave {} {
	variable Code
	variable regs
	variable text

	set R {}
	foreach { reg } [::array names regs] {
	    lappend R $regs($reg)
	}
	set R [lsort -real -index 0 $R]

	if { $text ne {} } {
	    lappend Code [list $R $text]
	}

	exprStart
    }

    proc compile { expr } {
	variable Code {}

	exprStart
	expression::parse $expr [expression::prep-tokens $::expression::optable] $::expression::optable ::tna::Emit
	exprSave

	return $Code
    }
    proc expr { expr } {
	set expr  [regsub -all -line -- {((^[ \t]*)|([ \t]+))#.*$} $expr  { }] 	; # Comment removal

	set code [compile $expr]

	if { $::tna::debug } {
	    foreach stmt $code {
		puts ""
		if { $::tna::debug == 2 } {
		    lassign $stmt regs text 

		    puts [join $regs \n]
		    puts ""
		    puts [join $text \n]
		    puts ""
		}
		puts [::tna::disassemble {*}$stmt] 
	    }
	}

	foreach stmt $code {
	    uplevel 1 [list ::tna::execute {*}$stmt]
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
	    lassign $r n type item name : drep data i t dims slice

	    switch $item {
		none -
		anox  -
		anon  { append listing [format " %4d  %-8s %-14s  %8s\n" $n $item $name $type] }
		vect  { append listing [format " %4d  %-8s %-14s  %8s	%d\n" $n $item $name $type $data] }
		const { append listing [format " %4d  %-8s %-14s  %8s	%f\n" $n $item $name $type $data] }
		tna   {
		    if { $drep eq "bytes" } {
			append listing [format " %4d  %-8s %-14s  %8s	%10s : %s %s\n" $n $item $name $type bytes $dims $slice]
		    } else {
			append listing [format " %4d  %-8s %-14s  %8s	0x%08x : %s %s\n" $n $item $name $type $data $dims $slice]
		    }
		}
		ivar -
		ovar -
		xvar { append listing [format " %4d  %-8s %-14s  %8s	%s\n" $n $item $name $type $data] }
		default { append listing $r "\n" }
	    }
	}
	append listing	"#\n"
	append listing	"#\n"

	append listing	"# Text\n"
	append listing	"#\n"
	set n 0
	foreach { instr } $text {
	    lassign $instr I R0 R1 R2

	    append listing [format " %4d    %4d %25s  %10s %10s %10s\n"	\
	    	[incr n] [format %4d $I] $OpcodesR($I) [lindex $regs $R0 3] [lindex $regs $R1 3] [lindex $regs $R2 3]]
	}

	return $listing
    }
}


