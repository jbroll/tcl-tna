
namespace eval tna {
    proc disassemble { regs text registers nreg } {
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

	append listing 	"# TNA Disassembly Listing\n"
	append listing	"#\n"
	append listing	"#\n"
	append listing	"# Registers\n"
	append listing	"#\n"

	foreach r $regs {
	    lassign $r n type item name : drep data i t dims slice

	    switch $item \
		$::tna::TNA_ITEM_none  -												\
		$::tna::TNA_ITEM_anox  -												\
		$::tna::TNA_ITEM_anon  { append listing [format " %4d  %-8s %-14s  %8s\n" $n $item $name $type] }			\
		$::tna::TNA_ITEM_vect  { append listing [format " %4d  %-8s %-14s  %8s	%d\n" $n $item $name $type $data] }		\
		$::tna::TNA_ITEM_const { append listing [format " %4d  %-8s %-14s  %8s	%f\n" $n $item $name $type $data] }		\
		$::tna::TNA_ITEM_tna   {
		    if { $drep eq "bytes" } {
			append listing [format " %4d  %-8s %-14s  %8s	%10s : %s %s\n" $n $item $name $type bytes $dims $slice]
		    } else {
			append listing [format " %4d  %-8s %-14s  %8s	0x%08x : %s %s\n" $n $item $name $type $data $dims $slice]
		    }
		}															\
		$::tna::TNA_ITEM_ivar -													\
		$::tna::TNA_ITEM_ovar -													\
		$::tna::TNA_ITEM_xvar { append listing [format " %4d  %-8s %-14s  %8s	%s\n" $n $item $name $type $data] }		\
		default { append listing $r "\n" }
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
