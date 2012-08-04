
    method  set-tcl { slice body } {
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
	    append item "\$$ax "
	}

	set body [subst -novariables					\
	         [regsub -all {%([a-zA-Z][0-9a-zA-Z]*)(\(([^)]+)\))?} 	\
	    	 [string map { [ \\[ } $body]    			\
			 "\\\[\[\\1 slice-get [list \\3] \$item]]"]]

	set expr [string map [list &&&& "[my slice-set $slice] \[expr {$body}] $item"] $expr]

	if { $::tna::debug } { puts $expr; flush stdout }
	if { 1 } $expr
    }

    method run { slice body } {
	set body [subst -novariables					\
	         [regsub -all {%([a-zA-Z][0-9a-zA-Z]*)(\(([^)]+)\))?} 	\
	    	 [string map { [ \\[ } $body]    			\
			 "\\\[\[\\1 slice-get [list \\3] \$item]]"]]

	::tna::sliceloop $dims [mkslice $dims $slice] $body
    }

