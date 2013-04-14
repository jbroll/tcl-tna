
critcl::cheaders arec.h
critcl::csources arec.c
critcl::tsources arec.tcl

namespace eval arec {
    variable type  {}

    proc typedef { args } {
	set stype struct

	      if { [llength $args] == 2 } { lassign $args         type body
	} elseif { [llength $args] == 3 } { lassign $args stype  type body 
	} elseif { [llength $args] == 4 } { lassign $args stype stype body type
	} else { error "too many args" }

	set ::arec::prefix {}
	set ::arec::type [::arec::add_type $type $stype]

	eval [::string map { , { } } $body]

	proc [namespace tail $type] { args } [subst { ::\$::arec::type add-field $type {*}\$args}]
    }

    proc add-field { type args } { ::$::arec::type add-field $type {*}$args }

    proc char   { args } { add-field char   {*}$args }
    proc uchar  { args } { add-field uchar  {*}$args }
    proc short  { args } { add-field short  {*}$args }
    proc ushort { args } { add-field ushort {*}$args }
    proc int    { args } { add-field int    {*}$args }
    proc long   { args } { add-field long   {*}$args }
    proc float  { args } { add-field float  {*}$args }
    proc double { args } { add-field double {*}$args }
    proc string { args } { add-field string {*}$args }
    proc char*  { args } { add-field string {*}$args }

    critcl::ccode {
	#include "arec.h"

	extern ARecField ARecTypesInst;
	extern ARecType  ARecTypesType;
	extern int ARecInstObjCmd();
	extern int ARecDelInst();
    }

#   critcl::cproc add_type { Tcl_Interp* ip Tcl_Obj* type int stype } Tcl_Obj* { 
#	ARecTypeCreate(ip, type, stype);
#
#	return type;
#    }

    critcl::ccommand add_type { data ip objc objv } { ARecTypeCreateObjCmd(ip, objc, objv); }
    critcl::cinit {
	ARecInit(ip);
    } { }
}

package provide arec 1.0

