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
	     short { s 2  {} }      ushort { s 2 u }      int { i 4  {} }      uint { i 4 u }
	swap-short { S 2  {} } swap-ushort { S 2 u } swap-int { I 4  {} } swap-uint { I 4 u }
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
	set data [tna::malloc [red x $args { set sum [expr { $sum*$x }] }]]
    }
    method  slice-get { axes slice } {
	set proc  ::tna::slice[incr ::tna::tnaN]-get

	set EXPR "\[expr { [tna::mkex $dims $size [tna::indx $dims $slice] $axes] }]"

	puts $EXPR

	proc   $proc $axes "tna::get_$sign$type $data $EXPR"
	return $proc
    }
    method  slice-set { axes slice } {
	set proc  ::tna::slice[incr ::tna::tnaN]-set

	set EXPR "\[expr { [tna::mkex $dims $size [tna::indx $dims $slice] $axes] }]"

	proc   $proc "value $axes" "::tna::set_$sign$type $data $EXPR \$value"

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

	if { 1 } $expr

	foreach slice [info proc ::tna::slice*] { rename $slice {} }
    }
    method data {} { return $data }

    method list-helper { dims offs } {
	set d [lindex $dims 0]
		
	if { [llength $dims] == 1 } {
	    for { set i 0 } { $i < $d } { incr i } {
		lappend reply [tna::get_$sign$type $data $offs]
		incr offs $size
	    }    
	} else {

	    for { set i 0 } { $i < $d } { incr i } {
		lappend reply [my list-helper [lrange $dims 1 end] $offs]

		set sum $size
		incr offs [red x [lrange $dims 1 end] { set sum [expr { $sum*$x }] }]
	    }
	}

	return $reply
    }
    method list {} { return [my list-helper [lreverse $dims] 0] }
}

