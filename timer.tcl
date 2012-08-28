
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

