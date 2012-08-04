
package provide tna-vm 0.1

critcl::tsources tna-vm.tcl tna-util.tcl	; # This file is a tcl source file for the package
critcl::csources tna-vm.c			; # The virtual machine
critcl::cheaders tna-vm.h generic.h 
critcl::cdefines TNA_* ::tna

critcl::cflags -O3
critcl::clibraries -lm

source tna-util.tcl


critcl::ccode {
    #include <stdio.h>
    #include "/Users/john/src/tna/generic.h"
    #include "/Users/john/src/tna/tna-vm.h"		/* The cheaders directive above didn't seem to take?	*/


    extern OpTable OpCodes[];
}
namespace eval tna {			  # This array defines the types avaialble in the package.
    set ::tna::reglen 1024

    set Types {
	      char { "signed char"      int     %d }
	     uchar { "unsigned char"    int     %d }
	     short { short		int     %d }
	    ushort { "unsigned short"	int     %d }
	       int { int 		int     %d }
	      uint { "unsigned int"	long    %u }
	      long { long		long   %ld }
	     ulong { "unsigned long"	ulong  %lu }
	     float { float		double  %f }
	    double { double		double  %f }
    }

    set  axes { x y z u v }		; # The names of the axis index variables
    set naxes [llength $axes]

    set i 1
    foreach { type def } $::tna::Types { 
	lassign $def ctype xtype format 
	critcl::cproc malloc_$type { long size } long "return (long) malloc(size*sizeof($ctype));"

	set ::tna::Type($type) $i
	incr i
    }
    foreach { type def } $::tna::Types { 
	lassign $def ctype xtype format 
	critcl::cproc sizeof_$type { long size } long "return sizeof($ctype);"
    }

    critcl::cproc opcodes { Tcl_Interp* ip } void {
	int i;
	Tcl_Obj *tnaOpcodes = Tcl_NewStringObj("::tna::Opcodes", -1);

	for ( i = 0; i < INSTR_END; i++ ) {
	    Tcl_Obj *opname = Tcl_NewStringObj(OpCodes[i].name, -1);
	    Tcl_Obj *opcode = Tcl_NewIntObj(i);

	    Tcl_ObjSetVar2(ip, tnaOpcodes, opname, opcode, TCL_GLOBAL_ONLY);
	}
    }

    critcl::cproc execute { Tcl_Interp* ip Tcl_Obj* text Tcl_Obj* registers } ok {


	return TCL_OK;
    }

}

if { [::critcl::compiled] } { ::tna::opcodes }


proc tna::indx { dims indx } {			  # Parse the slice syntax into a list.
    foreach d $dims x [split $indx ,] {
	if { $d eq {} } { break }

	set indx [split $x :]

	if { [llength $indx] == 1 && $x != "*" } {
	    if { $x < 0 } { set x [expr $d+$x] }
	    set s $x
	    set e $x
	    set i  1
	} else {
	    lassign $indx s e i


	    if { $s eq {} || $s eq "*" } { set s  0 	      }
	    if { $e eq {}              } { set e [expr $d-1]  }
	    if { $i eq {}              } { set i  1 	      }

	    if { $s < 0 } { set s [expr $d+$s] }
	    if { $e < 0 } { set e [expr $d+$e] }
	}

	lappend list [list $s $e $i]
    }

    return $list
}

