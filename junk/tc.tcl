
lappend auto_path lib

package require tna-as

source expression.tcl

namespace eval tna {
	variable code tmps next

	expr { expr } {
	    set code [tna::as create as]

	    expression::parse $expr [expression::prep-tokens $::expression::optable] $::expression::optable [list [self] compile]

	    ::tna::execute [code registers] [code text]

	    tna::as destroy
	}
	method next {} { return incr next }

	method tmpregs { type } {
	    if { [info exists tmps($type)] && $tmps($type) ne {} } {
		return [pop tmps($type)]
	    }

	    set reg "_[my next]"

	    as register $reg * $type
	    return $reg 
	}

	method typeof { x } {
	    puts "typeof $x"

	    if { [string is integer $x] } {
		if { ![info exists $ints($x)] } {
		    tna::value 
		    as register $x * int
		}
		return    int
	    }
	    if { [string is  double $x] } {
		if { ![info exists $ints($x)] } {
		    tna::value 
		    as register $x * int
		}
		return dbl
	    }

	    $x type
	}

	method compile { op args } {
	    puts "$op : $args"

	    switch $op {
		= {
		    tna::declair $args regs

		    $code equ {*}$regs
		}
		* { my binop $op {*}$args }
		default {
		    error "unknown operator $op"
		}
	    }
	}
    }
}

tna::array create A float 10 10
tna::array create B float 10 10

tna::expr create X { A = 1 * 3 }
tna::expr create X { B = 2 }
tna::expr create X { A = A * B }

tna::print B

