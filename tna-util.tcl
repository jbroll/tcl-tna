
namespace eval tna {
    if { [::critcl::compiled] } {
	::tna::opcodesX
	set i 0
	foreach { tnaType CType pType pFmt getType getFunc scan } $::tna::Types {
	    set ::tna::TNA_TYPE_$tnaType [incr i]

	    set ::tna::TypesScan($tnaType) $scan
	    if { [::tna::sizeof_long] == 8 } {
		set  ::tna::TypesScan(long) w
		set ::tna::TypesScan(ulong) w
	    }

	    set TypesR($i)  $tnaType
	}

	set i 0
	foreach tnaItem { none const vect tna anon anox ivar ovar xvar } {
	    set ::tna::TNA_ITEM_$tnaItem [incr i]
	}
    }
}

