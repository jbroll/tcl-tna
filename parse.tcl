
namespace eval tna {
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

    proc anonreg { type { regtype {} } } { 				# Allocate a anon register
	variable R

	if { $regtype eq {} } {
	    set regtype $::tna::TNA_ITEM_anon 
	}

	if { [llength $::tna::reglist] == 0 } {
	    set reg   [incr ::tna::nreg]
	    set name @$reg
	} else {
	    set name [lindex $::tna::reglist end]
	    set ::tna::reglist [lrange $::tna::reglist 0 end-1]
	    set reg [string range $name 1 end]
	}

	set ::tna::regs($name) [list $reg $type $regtype $name : $::tna::TNA_ITEM_anon $regtype {} $type {} {}]
	$R set $reg type $type item $regtype name $name
	
	return $reg
    }
    proc dispose { name } {				# Push anon register on list for reuse
	if { [string index $name 0] eq "@"	\
	  && [lindex $::tna::regs($name) 2] eq $::tna::TNA_ITEM_anon } {
	    lappend ::tna::reglist $name
	}
    }
    proc register { name value { type {} } { item {} } } {		# Allocate a register for a value of some type
	set dims {}
	set slic {}

	if { [info command $name] ne {} } {		# The item is a command - Ask it about its tna interface.
	    set item $::tna::TNA_ITEM_tna
	    set drep [$name drep]
	    set type [$name type]
	    set dims [$name dims]
		set data [$name data]
	    set flds _long

	    if { $drep eq "bytes" } {
		set data [bap $data]
	    }

	    set slic [$name indx]
	} elseif { [string is int    $value] } {	# Int
	    set item $::tna::TNA_ITEM_const
	    set data $value
	    set drep  value
	    if { $type eq {} } {
		set type $tna::TNA_TYPE_int
		set flds _int
	    } else {
		set name $name-$type
		set flds _int
	    }
	} elseif { [string is double $value] } {	# Double
	    set item $::tna::TNA_ITEM_const
	    set data $value
	    set drep  value
	    if { $type eq {} } {
		set type $tna::TNA_TYPE_double
		set flds _double
	    } else {
		set name $name-$type
		set flds _double
	    }
	} elseif { $name in $::tna::Axes } {		# An axis letter.
	    set item $::tna::TNA_ITEM_vect
	    set type $::tna::TNA_TYPE_int
	    set data [::expr -([lsearch $::tna::Axes $name]+1)]
	    set drep  vect
	    set flds _int
	} else {
	    if { $item ne {} } {
		set item $item
		set data $name
		set drep value
		set type $tna::TNA_TYPE_double
		set flds _double
	    } else {					# Huh?
		error "cannot identify item : $name"
	    }
	}

	set reg [incr ::tna::nreg]
	set ::tna::regs($name) 	[list $reg $type $item $name : $drep $data {} $type $dims $slic]

	variable R
	variable RI
	set RI($name) $reg
	$R set $reg type  $type item $item name $name drep [set ::tna::TNA_DREP_$drep] 
	$R set $reg value $flds $data
    }
    proc register-type { name } {
	variable R
	variable RI

	#return [$R $reg get type]
	return [lindex ::tna::regs($name) 1]
    }


    proc promote { c regc typec args } {		# Promote args to common widest type, emit conversion code
	variable text
	variable TypesR

	upvar $c C
	upvar $regc regC
	upvar $typec typeC

	set typeC $tna::TNA_TYPE_none
	foreach { reg type Name } $args {
	    set typeC [::expr max($typeC, $type)]
	}

	foreach { reg type Name } $args {
	    upvar $Name N

	    if { $type ne $typeC } {
		set N [anonreg $typeC]
		lappend text [list $::tna::OpcodesX(tna_opcode_$TypesR($type)_$TypesR($typeC)) $reg 0 $N]
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
	variable R
	variable RI

	if { [info commands $name] eq {} } {
	    error "only an array can be indexed"
	}

	lookup $name - - - -

	set reg [anonreg $tna::TNA_TYPE_int]

	foreach i { 1 2 5 6 7 8 9 10 } {
	    lset regs(@$reg) $i [lindex $regs($name) $i]
	}
	$R setdict $reg [$R getdict $RI($name) type item drep]

	lset regs(@$reg) end [$name indx $args]
	#$R $reg axis setdict [lindex $regs(@$reg) end]

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
	variable R
	variable RI

	if { [info exists ::tna::regs($name)] } {
	    switch [lindex $::tna::regs($name) 2] 				\
	     $::tna::TNA_ITEM_ivar -						\
	     $::tna::TNA_ITEM_xvar {}						\
	     ovar {
		 lset ::tna::regs($name)] 2 $::tna::TNA_ITEM_xvar
		 $R set $RI($name) item $::tna::TNA_ITEM_xvar 
	     }									\
	     default {
		 error "existing value is not a tcl reference : $name"
	     }

	    return $name
	}
	     
	set reg [incr ::tna::nreg]

	set ::tna::regs($name) 	\
	    [list $reg $tna::TNA_TYPE_double $tna::TNA_ITEM_ivar $name : value $name {} $::tna::TNA_TYPE_double {} {}]

	set RI($name) $reg 
	$R set $reg type $tna::TNA_TYPE_double item $tna::TNA_ITEM_ivar name $name drep $::tna::TNA_DREP_value
	$R set $reg value _string $name

	return $name
    }

    proc assign { op a b } {				# Emit code for assignment
	variable regs
	variable text
	variable TypesR
	variable R
	variable RI
	
	lookup $a regA typeA itemA - {} $::tna::TNA_ITEM_ovar
	lookup $b regB typeB -     -

	if { $typeA == $::tna::TNA_ITEM_any } { set typeA $typeB }
	if { $typeB == $::tna::TNA_ITEM_any } { set typeB $typeA }

	if { $b eq "X" } {						# Add X register fixup
	    set tmp [anonreg $typeB $tna::TNA_ITEM_anox]
	    lappend text [list $::tna::OpcodesX(tna_opcode_xxx_$TypesR($typeB)) $regB 0 $tmp]
	    set ::tna::X [set regB $tmp]
	    set regB $tmp
	}
	if { $itemA eq $::tna::TNA_ITEM_ivar } {					# Fix up ivar (input) to be xvar
	    lset ::tna::regs($a) 2 $::tna::TNA_ITEM_xvar
	    $R set $RI($a) item $::tna::TNA_ITEM_xvar
	}

	# If the types are the same and the target is a tmp register,
	# change the target of the previous instr
	#
	if { $typeA eq $typeB && [info exists regs(@[lindex $text end end])] } {
	    lset text end end $regA						
	} else {
	    lappend text [list $::tna::OpcodesX(tna_opcode_$TypesR($typeB)_$TypesR($typeA)) $regB 0 $regA]
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
	variable TypesR

	lookup $a regA typeA itemA -

	switch $op {
	 dec - udec { set incr -1 }
	 inc - uinc { set incr  1 }
	}

	set tmp [anonreg $typeA]

	switch -- $op {
	 inc - dec {
	    lookup  $incr reg1 type1 -     - $typeA

	    lappend text [list $::tna::OpcodesX(tna_opcode_$TypesR($typeA)_$TypesR($typeA)) $regA     0 $tmp]
	    lappend text [list $::tna::OpcodesX(tna_opcode_add_$TypesR($typeA))             $regA $reg1 $regA]

	    return @$tmp
	 }
	 uinc - udec {
	    lookup  $incr reg1 type1 -     - $typeA

	    lappend text [list $::tna::OpcodesX(tna_opcode_add_$TypesR($typeA))      $regA $reg1 $regA]

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
	variable TypesR

	lookup $a regA typeA itemA dataA
	lookup $b regB typeB itemB dataB

	if { $typeA == $tna::TNA_ITEM_any } { set typeA $typeB }
	if { $typeB == $tna::TNA_ITEM_any } { set typeB $typeA }

	if { $a eq "X" } {					  # X register fixup
	    if { $::tna::X eq {} } {
		set tmp [anonreg $typeA $tna::TNA_ITEM_anox]
		lappend text [list $::tna::OpcodesX(tna_opcode_xxx_$TypesR($typeA)) $regA 0 $tmp]
		set ::tna::X [set regA $tmp]
	    } else {
		set regA $::tna::X
	    }
	}
	if { $b eq "X" } {					  # X register fixup
	    if { $::tna::X eq {} } {
		set tmp [anonreg $typeB $tna::TNA_ITEM_anox]
		lappend text [list $::tna::OpcodesX(tna_opcode_xxx_$TypesR($typeB)) $regB 0 $tmp]
		set ::tna::X [set regB $tmp]
	    } else {
		set regB $::tna::X
	    }
	}

	if { $itemA eq $::tna::TNA_ITEM_const && $itemB eq $::tna::TNA_ITEM_const } {		; # Try constant folding
	    set c [::expr "\$dataA $::expression::opers($op) \$dataB"]

	    lookup $c - - - -

	    return $c
	} else {
	    promote C regC typeC $regA $typeA A $regB $typeB B
	    dispose $a
	    dispose $b
	    lappend text [list $::tna::OpcodesX(tna_opcode_${op}_$TypesR($typeC)) $A $B $regC]

	    return $C
	}
    }

    proc Emit { op args } { return [$op $op {*}$args] }

    proc semi { op } {
	exprSave
	exprStart
    }

    variable R [tna::Register create ::tna::reg 0]

    proc exprStart {} {
	variable R

	variable regs
	variable       X {}
	variable    text {}
	variable    nreg  0
	variable reglist {}

	$R length 0

	::array unset regs

	set regs(0) [list 0 $::tna::TNA_ITEM_any $::tna::TNA_ITEM_const 0 : 0 0 {} $::tna::TNA_TYPE_int {} {}]

	$R set 0 type  $::tna::TNA_ITEM_any item $::tna::TNA_ITEM_const name 0
    }
    proc exprSave {} {
	variable Code
	variable regs
	variable text
	variable R

	set r {}
	foreach { reg } [::array names regs] {
	    lappend r $regs($reg)
	}
	set r [lsort -real -index 0 $r]

	if { $text ne {} } {
	    lappend Code [list $r $text [$R getbytes]  [$R length]]
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


	    lassign $stmt a b c d 

	    #puts "$d [format %x [bap $c]] [string length $c] $c"
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

}
