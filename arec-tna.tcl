

oo::class tna::arec {
    variable arec
    accessor arec

    constructor { name type length } {
	set arec [$type new xxx $length]
    }

    method data { return [$arec data] }
    method drep { return  ptr }
    method type { return arec }
    method dims { return [$arec length] }

    method indx { args } { return [list 0 [$arec length] [$arec size]] }

    method dot  { 
	# In a new register adjust the data pointer by the offset to the dotted field
	# update the type to the data type of the field

	# return the new register.
    }

    method list { args } {
	set start 0
	set end   end

	set indx [split [lindex $args 0] :]
	if { [llength $indx] == 2 && [string is in [lindex $indx 0]] && [string is int [lindex $indx 1]] } {
	    lassign $indx start end

	    if { $start eq {} } { set start 0 }
	    if { $end   eq {} } { set end end }

	    set args [lrange $args 1 end]

	}

	tailcall $start $end $arec getlist {*}$args
    }
    method destroy {} {}
    method print   {} {}
}

if { [info commands ::typedef::datatypes] } {
    foreach datatype [::typedef::datatypes] {
	oo::class ::tna::$typedef [list superclass ::tna::arec]
    }
}

