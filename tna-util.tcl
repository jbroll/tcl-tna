
namespace eval tna {
    if { [::critcl::compiled] } {
	::tna::opcodesX
	set i 0
	foreach { tnaType CType pType pFmt getType getFunc scan } $::tna::Types {
	    set ::tna::TypesX($tnaType) [incr i]

	    set ::tna::TypesScan($tnaType) $scan
	    if { [::tna::sizeof_long] == 8 } {
		set  ::tna::TypesScan(long) w
		set ::tna::TypesScan(ulong) w
	    }
	}
    }
}

