
set vector { X Y Z U V }

proc matrix-eval { fmt expr args } {
    set matrix [matrix [format $fmt 0] {*}$args]

    set expr [string map { X $X Y $Y Z $Z U $U V $V } $expr]

    foreach axis [lrange $::vector 0 [llength $args]-1] len $args {
	append code "foreach $axis \[iota 0 [expr $len-1]] \{ "
    }
    append code "lset matrix [string map { X $X Y $Y Z $Z U $U V $V } [lreverse [lrange $::vector 0 [llength $args]-1]]] "
    append code "\[format $fmt \[expr $expr]]"
    append code [string map { \\ { } } [lrepeat [llength $args] "\}"]]

    eval $code

    return $matrix
}

proc matrix { value n args } {
    set value [lrepeat $n $value]

    if { [llength $args] != 0 } {
	set value [matrix $value {*}$args]
    }

    return $value
}

set IntOnly { % & | ^ ~ << >> }

