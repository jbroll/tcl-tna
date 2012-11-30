
critcl::cheaders arec.h
critcl::csources arec.c
critcl::tsources arec.tcl

namespace eval arec {
    variable types {}
    variable type  {}

    proc types {} { return $::arec::types }

    proc typedef { type body } {
	lappend  ::arec::types [set ::arec::type [NewType $type]]

	eval $body
    }

    proc char   { args } { $::arec::type add-field char   {*}$args }
    proc uchar  { args } { $::arec::type add-field uchar  {*}$args }
    proc short  { args } { $::arec::type add-field short  {*}$args }
    proc ushort { args } { $::arec::type add-field ushort {*}$args }
    proc int    { args } { $::arec::type add-field int    {*}$args }
    proc float  { args } { $::arec::type add-field float  {*}$args }
    proc double { args } { $::arec::type add-field double {*}$args }
    proc char*  { args } { $::arec::type add-field string {*}$args }

    critcl::ccommand NewType { data interp objc objv } { return ARecNewType(interp, objc, objv); }
}

package provide arec 1.0

