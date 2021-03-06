# Make some procs to allow the evaluation of "tna-register.h"
#
package require arec

namespace eval tna {
	proc typedef { struct stype body type } {
	    arec::typedef $struct $stype [regsub -all {\[} $body { [tna::xexpr }] ::tna::$type 
	}
	proc xexpr { args } {
	    set args [regsub {([a-zA-Z_][a-zA-Z_0-9]*)} $args {$::\1}]
	    ::expr $args
	}
	proc #define { name value } {
	    set ::$name $value
	}

	proc ::/* { args } {}

	proc xsource { data } {
	    set data [regsub -all -line {^#define } $data {tna::#define }]
	    eval $data
	}

    xsource {
	source register.h
    }
}
