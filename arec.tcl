
critcl::cheaders arec.h
critcl::csources arec.c
critcl::tsources arec.tcl

namespace eval arec {
    variable types {}
    variable type  {}

    proc types {} { return $::arec::types }

    proc typedef { type body } {
	lappend  ::arec::types [set ::arec::type [::arec::add_type $type]]

	eval $body

	proc ::arec::$type args [list ::$::arec::type add-struct {*}\$args]
    }

    proc char   { args } { ::$::arec::type add-field char   {*}$args }
    proc uchar  { args } { ::$::arec::type add-field uchar  {*}$args }
    proc short  { args } { ::$::arec::type add-field short  {*}$args }
    proc ushort { args } { ::$::arec::type add-field ushort {*}$args }
    proc int    { args } { ::$::arec::type add-field int    {*}$args }
    proc long   { args } { ::$::arec::type add-field long   {*}$args }
    proc float  { args } { ::$::arec::type add-field float  {*}$args }
    proc double { args } { ::$::arec::type add-field double {*}$args }
    proc string { args } { ::$::arec::type add-field string {*}$args }

    critcl::ccode {
	#include "arec.h"

	extern ARecInst ARecDTypesInst;
	extern ARecType ARecDTypesType;
	extern int ARecInstObjCmd();
	extern int ARecDelInst();
    }
    critcl::ccommand add_type { data interp objc objv } { return ARecTypeCreateObjCmd(interp, objc, objv); }
    critcl::cinit {
	ARecInit(ip);
    } { }
}

package provide arec 1.0

