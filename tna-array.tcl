
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
    export varname

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

