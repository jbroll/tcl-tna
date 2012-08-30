#!/usr/bin/env tclkit8.6
#

package require tcltest

proc matrix { value n args } {
    set value [lrepeat $n $value]

    if { [llength $args] != 0 } {
	set value [matrix $value {*}$args]
    }

    return $value
}

::tcltest::test find-tna { See about package require tna } {
    lappend auto_path lib

    package require tna
    source tna-tcl.tcl
} {}

set IntOnly { % & | ^ ~ << >> }


foreach { types result } { { char uchar short ushort int uint long } 3 { float double } 3.0 } {
    foreach type $types {
	::tcltest::test 3x3-$type-1.0 { Simple array math } -body {
	    tna::array create a $type 3 3

	    tna::expr { a = 3 }
	    a list
	} -cleanup {
	    a destroy
	} -result  [matrix $result 3 3]
    }
}

foreach { types fmt } { { char uchar short ushort int uint long } %d { float double } %.1f } {
    foreach type $types {
	foreach dim { 1 { 1 1 } { 2 2 } { 3 3 } { 3 3 3 } { 1 2 3 } { 3 2 1 } { 10 10 10 } { 10 10 10 10 10 } } {
	    foreach { c = a op b } {
		      3 = 2 + 1
		     -2 = 2 - 4
		      8 = 2 * 4
		      2 = 4 / 2

		      4 =  1 << 2
		      1 =  5 %  2
		      0 =  8 %  2
		      2 =  6 &  2
		      3 =  1 |  2
		      
		      1 =  5 >  1
		      0 =  5 <  1
		      1 =  5 >= 5
		      1 =  5 <= 5
		      1 =  5 == 5
		      0 =  5 == 4

	    } {
		if { $type in { float double } && $op in $IntOnly } { continue }

		::tcltest::test "$dim $type $op 1.0" "Simple array math : $c = $a $op $b" -body {
		    tna::array create a $type {*}$dim
		    tna::array create b $type {*}$dim
		    tna::array create c $type {*}$dim

		    tna::expr "a = $a"
		    tna::expr "b = $b"
		    tna::expr "c = a $op b"
		    c list
		} -cleanup {
		    a destroy
		    b destroy
		    c destroy
		} -result  [matrix [format $fmt $c] {*}$dim]
	    }
	}
    }
}



::tcltest::test big-array-1.0 { Process large arrays } {
    tna::array create a double 2048 2048
    tna::array create b double 2048 2048
    tna::array create c double 2048 2048
    tna::value create d double 0

    tna::expr { a = X+Y }
    tna::expr { b = 2 }

    foreach i [iota 1 100] {
	tna::expr { c = a*a + b*b + 2.0 * a * b }
    }

    tna::expr { d = c[0,0] }
    d list
} {4.0}

