
namespace eval tna {
    if { [::critcl::compiled] } {
	if { [RegisterSize] != [Register size] } { puts stderr "WARNING tna : RegisterSize [RegisterSize] != Register size [Register size]" }

	::tna::opcodesX

	set i 0
	set ::tna::TNA_TYPE_none 0
	foreach { tnaType CType pType pFmt getType getFunc scan } $::tna::Types {
	    set ::tna::TNA_TYPE_$tnaType [incr i]

	    set ::tna::TypesScan($i) $scan


	    set TypesR($i)  $tnaType
	}
	set TypesR(101) zero
	if { [::tna::sizeof_long] == 8 } {
	    set  ::tna::TypesScan([set TNA_TYPE_long]) w
	    set ::tna::TypesScan([set TNA_TYPE_ulong]) w
	}

	set i 100
	foreach tnaItem $::tna::Items {
	    set ::tna::TNA_ITEM_$tnaItem [incr i]
	    set ItemsR($i) $tnaItem
	}

	set i 200
	foreach tnaDRep $::tna::DReps {
	    set ::tna::TNA_DREP_$tnaDRep [incr i]
	}
    }
}

