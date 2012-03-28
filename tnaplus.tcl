
proc iota { fr to { in 1 } } {
    set fr [expr $fr]
    set to [expr $to]
    for { set res {} } { $fr <= $to } { incr fr $in } {lappend res $fr } 
    set res
}
proc red { args } {
    return [uplevel [subst {
        set _[info frame] {}
        foreach [lrange $args 0 end-1] { set     _[info frame] \[eval {[lindex $args end]}] }
        set _[info frame]
    }]]
}

critcl::tsources tnaplus.tcl		; # This file is a tcl source file for the package
critcl::cdefines TNA_* ::tna

namespace eval tna {			  # This array defines the types avaialble in the package.
    array set Types {
	      byte { "unsigned char"    int     %d }
	     short { short		int     %d }
	    ushort { "unsigned short"	int     %d }
	       int { int 		int     %d }
	      uint { "unsigned int"	long    %d }
	      long { long		long   %ld }
	     float { float		double  %f }
	    double { double		double  %f }
    }

    set  axes { x y z u v }		; # The names of the axis index variables
    set naxes [llength $axes]
}

set i 0
foreach { type def } [array get ::tna::Types] {
    incr i				; # Generate some defines to identify the data types
    lassign $def ctype rtype spec
    append ::tna::Typedefs "#define TNA_$type $i\n"

    set Type [string totitle $rtype]	; # Generate a target case to extract and assign each data type.
    append ::tna::Typecase [subst -nocommands {
	 case TNA_$type: {
	    Tcl_Obj *resultPtr;
	    $rtype   value;

	    if ( Tcl_ExprObj(interp, body, &resultPtr) != TCL_OK ) { return TCL_ERROR; }

	    if ( Tcl_Get${Type}FromObj(interp, resultPtr, &value) != TCL_OK ) {
		return TCL_ERROR;
	    }
	    Tcl_DecrRefCount(resultPtr);
	    (($ctype *) data)[offs] = value;
	    break;
	 }
    }]
}

critcl::ccode [subst -nobackslashes -nocommands {
    #include <stdlib.h>
					// Insert the typedefs and defines here.
    $::tna::Typedefs

    typedef struct _Axis {
	long	dims;			/* dimensions of the data	*/
	long	star;			/* slice start			*/
	long	incr;			/* increment			*/
	long	size;			/* slice size			*/
	long	step;			/* block size of the dimension	*/
    } Axis;

    typedef struct _Slice {		/* definition of the slice	*/
	void	*data;
	Axis	 ax[$::tna::naxes];
    } Slice;

    void prslice(Slice *s) {		// A little debugging function.
	int i;
	printf("Slice %p : data %p\n", s, s->data);
	printf("	dims	star	incr	size	step\n");
	for ( i = 0 ; i < 6; i++ ) {
	    printf("	%ld	%ld	%ld	%ld	%ld\n"
		    , s->ax[i].dims, s->ax[i].star, s->ax[i].incr, s->ax[i].size, s->ax[i].step);
	}
    }

    int sliceloop_axis(Tcl_Interp *interp, int type, long dims, Slice *s
	    	      , Tcl_Obj **Names, Tcl_Obj **X, Tcl_Obj* body, long base) {
	short *data = (short *)s->data;
	long   offs = 0;

	dims--;

	long     x;
	long	 d = dims;
	long ends = s->ax[dims].star + s->ax[dims].size;

	for ( x = s->ax[dims].star; x < ends; x += s->ax[dims].incr ) {
	    Tcl_SetLongObj(X[dims],  x);
	    Tcl_ObjSetVar2(interp, Names[dims], NULL, X[dims], 0);

	    offs = base + ((s->ax[d].star+((x*s->ax[d].incr)%(s->ax[d].size)))%s->ax[d].dims)* s->ax[d].step;

	    if ( !dims ) {
		switch ( type ) {		// Include the extraction cases for each type.
		 $::tna::Typecase
		}
	    } else {
		if ( sliceloop_axis(interp, type, dims, s, Names, X, body, offs) != TCL_OK ) { return TCL_ERROR; }
	    }
	}
	return TCL_OK;
    }
}]
critcl::cproc tna::sliceloop { Tcl_Interp* interp int type int dims long slice Tcl_Obj* axes Tcl_Obj* body } ok {
    Slice *s = (Slice *) slice;

    Tcl_Obj *X[6];
    int      nnames;
    Tcl_Obj **Names;

    int i;

    Tcl_ListObjGetElements(interp, axes, &nnames, &Names);
    for ( i = 0; i < dims; i++ ) {
	X[i] = Tcl_NewLongObj(0L);
    }

    if ( sliceloop_axis(interp, type, dims, s, Names, X, body, 0) != TCL_OK ) { return TCL_ERROR; }

    return TCL_OK;
}

proc tna::mkex { dims axes } {
    foreach d [iota 0 $dims-1] x $axes {
	lappend expr "((s->ax\[$d].star+(($x*s->ax\[$d].incr)%(s->ax\[$d].size)))%s->ax\[$d].dims)[expr { ($d==0) ? "" : "* s->ax\[$d].step" }]"
    }

    return "[join $expr "\n		  + "]"
}

proc tna::mkget { type ndim } {
    lassign $::tna::Types($type) ctype rtype spec

    critcl::cproc ::tna::get_$type$ndim "long slice long [join [lrange $::tna::axes 0 $ndim-1] " long "]" $rtype [subst {
	Slice *s = (Slice *)slice;
	long offs = [tna::mkex $ndim [lrange $::tna::axes 0 $ndim-1]];
	[printf "Get %p\[%ld]\\n" s->data offs]
	return (($ctype *)(s->data))\[offs];
    }]
}

set ::tna::debug 0
proc printf { format args } { if { $::tna::debug } { return "printf(\"$format\", [join $args ,]);" } }

proc tna::mkset { type ndim } {
    lassign $::tna::Types($type) ctype rtype spec

    critcl::cproc ::tna::set_$type$ndim "long slice $rtype value long [join [lrange $::tna::axes 0 $ndim-1] " long "]" $rtype [subst {
	Slice *s = (Slice *)slice;
	[printf "Inx [string repeat "%ld " $ndim]\\n" {*}[lrange $::tna::axes 0 $ndim-1]]
	//prslice(s);
	long offs = [tna::mkex $ndim [lrange $::tna::axes 0 $ndim-1]];
	[printf "Set %p\[%ld] = $spec\\n" s->data offs value]
	return (($ctype *)(s->data))\[offs] = value;
    }]
}

foreach type [array names ::tna::Types] {
    critcl::cproc tna::malloc_$type { items } long [subst {
	void *data = calloc(items, sizeof($ctype));
	[printf "Calloc %p\\n" data]
	return (long) data;
    }]

    foreach n [iota 1 $::tna::naxes] { tna::mkget $type $n }
}
critcl::cproc tna::free { long data } void { free((void *)data); }


critcl::cproc tna::mkslice { Tcl_Interp* interp long data Tcl_Obj* dims Tcl_Obj* slic } ok {
    Tcl_Obj **dimsList;
    int      ndims;
    Tcl_Obj **slicList;
    int      nslic;
    int	     i;
    Tcl_Obj **axisList;
    int      naxis;

    Slice *s = malloc(sizeof(Slice));

    s->data = (void *) data;

    if ( Tcl_ListObjGetElements(interp, dims, &ndims, &dimsList) != TCL_OK ) { return TCL_ERROR; }

    for ( i = 0; i < ndims; i++ ) {
	if ( Tcl_GetLongFromObj(interp, dimsList[i], &s->ax[i].dims) != TCL_OK ) { free(s);  return TCL_ERROR; }
    }

    if ( Tcl_ListObjGetElements(interp, slic, &nslic, &slicList) != TCL_OK ) { return TCL_ERROR; }


    s->ax[0].step = 1;
    for ( i = 1; i < ndims; i++ ) { s->ax[i].step = s->ax[i-1].step * s->ax[i-1].dims; }
    for ( i = 0; i < nslic; i++ ) {
	long star, ends, incr;

	Tcl_Obj sideList;
	int    nside;

	Tcl_ListObjGetElements(interp, slicList[i], &naxis, &axisList);

	if ( Tcl_GetLongFromObj(interp, axisList[0], &star) != TCL_OK ) { free(s);  return TCL_ERROR; }
	if ( Tcl_GetLongFromObj(interp, axisList[1], &ends) != TCL_OK ) { free(s);  return TCL_ERROR; }
	if ( Tcl_GetLongFromObj(interp, axisList[2], &incr) != TCL_OK ) { free(s);  return TCL_ERROR; }

	s->ax[i].star = star;
	s->ax[i].incr = incr;
	s->ax[i].size = ends - star + 1;
    }

    Tcl_SetLongObj(Tcl_GetObjResult(interp), (long) s);
    return TCL_OK;
}


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

oo::class create tna {
    variable type dims data

    constructor { Type args } {
	set type $Type
	set dims $args

	set sum 1
	set data [tna::malloc_$type [red x $args { set sum [expr { $sum*$x }] }]]
    }
    method  slice-get { indx axes } {
	set i 0
	set indx [split $indx ,]
	foreach x $indx {
	    switch -regexp -- $x {
		{^[0-9]+$} - {^.*:.*$} - {^\*$} - {^$}   { # Skip these slice specs }
		.* { set indx [lreplace $indx $i $i  *]	 ; # Replace the slice axis index with the user expression.
		     set axes [lreplace $axes $i $i $x]
		}
	    }
	    incr i
	}

	lappend ::tna::slices [set slice [tna::mkslice $data $dims [tna::indx $dims [join $indx ,]]]]

	return "tna::get_$type[llength $dims] $slice [join [lrange $axes 0 [llength $dims]-1]]"
    }
    method  set { slice body } {
	set item \$[join [lrange $::tna::axes 0 [llength $dims]-1] " \$"]	; # Parse the user value expression.
	set body [subst -novariables						\
	         [regsub -all {%([a-zA-Z][0-9a-zA-Z]*)(\(([^)]+)\))?} 		\
	    	 [string map { [ \\[ } $body]    				\
			 "\\\[\[\\1 slice-get [list \\3] \$item]]"]]

	lappend ::tna::slices [set slice [tna::mkslice $data $dims [tna::indx $dims $slice]]]

	uplevel [list ::tna::sliceloop [set ::tna::TNA_$type] [llength $dims] $slice $::tna::axes $body]

	tna::free-slices
    }
    proc ::tna::free-slices {} {
	foreach slice $::tna::slices { tna::free $slice }
	set ::tna::slices {}
    }

    method data {} { return $data }

    method list {} {					  # Return the data as a list.
	set items 1
	set items [red x $dims { set items [expr { $items*$x }] }]

	lappend ::tna::slices [set slice [tna::mkslice $data $items [list [list 0 $items 1]]]]

	set list [my List-Helper $slice [lreverse $dims] 0]
	tna::free-slices
 	return $list
    }
    method List-Helper { slice dims offs } {
	set d [lindex $dims 0]
		
	if { [llength $dims] == 1 } {
	    for { set i 0 } { $i < $d } { incr i } {
		lappend reply [tna::get_${type}1 $slice $offs]
		incr offs 1
	    }    
	} else {

	    for { set i 0 } { $i < $d } { incr i } {
		lappend reply [my List-Helper $slice [lrange $dims 1 end] $offs]

		set sum 1
		incr offs [red x [lrange $dims 1 end] { set sum [expr { $sum*$x }] }]
	    }
	}

	return $reply
    }
}

package provide tnaplus 1.0

