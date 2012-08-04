proc K { x y } { set x }
proc red { args } {
    return [uplevel [subst {
        set _[info frame] {}
        foreach [lrange $args 0 end-1] { set     _[info frame] \[eval {[lindex $args end]}] }
        set _[info frame]
    }]]
}

namespace eval tna {
    array set typeof {
	     short { s 2  0 }      ushort { s 2 0xFFFF }      int { i 4  0 }      uint { i 4 0xFFFFFFFF }
	swap-short { S 2  0 } swap-ushort { S 2 0xFFFF } swap-int { I 4  0 } swap-uint { I 4 0xFFFFFFFF }
    }

    set axes { x y z t u v }
    set tnaN 0
}

proc tna::indx { dims indx } {
    foreach d $dims x [split $indx ,] {
	if { $d eq {} } { break }

	set indx [split $x :]

	if { [llength $indx] == 1 && $x != "*" } {
	    set s $x
	    set e $x
	    set i 1
	} else {
	    lassign $indx s e i

	    if { $s eq {} || $s eq "*" } { set s  0 	      }
	    if { $e eq {}              } { set e [expr $d-1]  }
	    if { $i eq {}              } { set i  1 	      }
	}

	lappend list [list $s $e $i]
    }

    return $list
}

proc tna::mkex { dims size slice axes } {
    set width $size

    foreach d $dims s $slice x $axes {
	if { $d eq {} || $s eq {} || $x eq {} } { break }

	lassign $s s e i
	set n [expr $e-$s]

	lappend expr "($s+((\$$x*$i)%($n+1)))*$width"

	set width [expr { $width * $d }]
    }

    return [join $expr " + "]
}

oo::class create tna {
    variable type size dims data sign

    constructor { Type args } {
	set dims $args
	lassign $::tna::typeof($Type) type size sign

	set sum $size
	set data [binary format x[red x $args { set sum [expr { $sum*$x }] }]]
    }
    method  slice-get { axes slice } {
	set proc  ::tna::slice[incr ::tna::tnaN]-get

	set EXPR [tna::mkex $dims $size [tna::indx $dims $slice] $axes]

	if { $sign } {	set RETR "\[expr \$value & $sign]"
	} else 	     { 	set RETR "\$value" }

	proc   $proc $axes "binary scan $data x\[expr $EXPR]$type value;  return $RETR"
	return $proc
    }
    method  slice-set { axes slice } {
	set proc  ::tna::slice[incr ::tna::tnaN]-set

	set EXPR [tna::mkex $dims $size [tna::indx $dims $slice] $axes]

	proc   $proc "value $axes" "
	    set offs \[expr $EXPR]
	    set [my varname data] \[K \[string replace \$[my varname data] \$offs \[expr { \$offs+$size-1 }] \[binary format $type \$value]] \
	        \[unset [my varname data]]]
	"

	return $proc
    }
    method  set { slice body } {
	set expr "\t&&&&\n"

	foreach indx [tna::indx $dims $slice] ax $::tna::axes {
	    if { $indx eq {} } { break }

	    lassign $indx s e i

	    if { $s == $e } {
		set expr "set $ax $s;\n$expr"
	    } else {
		set op <=
		set z 0
		set n [expr ($e-$s)/$i]
		set d 1

		if { $s >= $e } {
		    set op >=
		    set n  0
		    set z [expr ($e-$s)/$i]
		    set d -1
		}

		set expr "for { set $ax $z } { \$$ax $op $n } { incr $ax $d } {\n$expr }"
	    }
	    append axes   "$ax "
	    append item "\$$ax "
	}

	set   map  { [ \\[ $ \\$ }
	set   body [subst [regsub -all {%([a-zA-Z][0-9a-zA-Z]*)(\(([^)]+)\))?} 	\
	    		[string map $map $body] 				\
			 "\\\[\[\\1 slice-get \$axes [list \\3]] \$item]"]]

	set   expr	\
	    [string map [list &&&& "[my slice-set $axes $slice] \[expr {$body}] $item"] $expr]

	eval $expr

	foreach slice [info proc ::tna::slice*] { rename $slice {} }
    }
    method data {} { return $data }

    method list-helper { dims offs } {
	if { [llength $dims] == 1 } {
	    binary scan $data x$offs$type[lindex $dims 0] row;  return $row
	} else {
	    set d [lindex $dims 0]

	    for { set i 0 } { $i < $d } { incr i } {
		lappend reply [my list-helper [lrange $dims 1 end] $offs]
	    }
	}

	return $reply
    }
    method list {} { return [my list-helper [lreverse $dims] 0] }
}

tna create y short    3   1
tna create x short    9   9

y set 0:1 { $x+1 }
x set *,* { %y }

puts [join [x list] \n]

