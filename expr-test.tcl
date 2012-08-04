
source expression.tcl

# Here is a little namespace to try out the parser.
#
namespace eval evaluate {
    proc    add { args } { expr [join $args +] }
    proc    sub { args } { expr [join $args -] }
    proc    mul { args } { expr [join $args *] }
    proc    div { args } { expr [join $args /] }

    proc assign { a b } { set ::$a $b }
    proc addasn { a b } { set ::$a [expr [set ::$a] + $b] }
    proc subasn { a b } { set ::$a [expr [set ::$a] - $b] }
    proc mulasn { a b } { set ::$a [expr [set ::$a] * $b] }
    proc divasn { a b } { set ::$a [expr [set ::$a] / $b] }

    proc    inc { a   } { incr ::$a    }
    proc    dec { a   } { incr ::$a -1 }
    proc   incu { a   } { incr ::$a    }
    proc   decu { a   } { incr ::$a -1 }

    proc uadd   { a   } { return [expr +$a] }
    proc usub   { a   } { return [expr -$a] }

    proc dolar  { a   } { set ::$a } 

    proc call { args } { {*}$args }
    proc indx { args } { set ::[lindex $args 0]([join [lrange $args 1 end] ,]) }


    proc eval { op args } { return [$op {*}$args] }
}


# Process the operator table to create the string map table that suffices
# for the lexical analyzer.
#
set tokens [expression::prep-tokens $expression::optable]

# A little test proc.
#
proc ? { a b } {
    
    # Parse the expresson in $a by calling the evaluator on each subexpression
    #
    set result [expression::parse $a $::tokens $expression::optable evaluate::eval]

    if { $result ne $b } { puts "$a : $result != $b" }
}

? xx xx			; # Simple string identity

? 4+5*7    39		; # Some math
? 4+(5*7)  39
? (4+5)*7  63

? +4  4			; # Unary ops
? -4 -4

? 9+4+6 19

? add(1,2,3) 6		; # Function call
? add(1+2,2+2*3,3) 14

set x 1
set y 2
? { x += $y } 3		; # NB: The "$" is recognized as the "deref"
? { x -= $y } 1		; #     operator and handled in the evaluator.
? { x *= $y } 2
? { x /= $y } 1

set a 3
? {4 + a++} 8

set d(4) 8
set a d
? {($a)[4]} 8

# Check some errors
#
catch { ? {$x .} rr. } reply; if { $reply ne {parse error at: x _@_ .  : unexpected token : x _@_ .} } { puts "fail : \$x . : $reply" }
catch { ? 4+8) xx    } reply;  if { $reply ne {parse error at: 8 _@_ )  : unexpected ")" : 8 ) } } { puts "fail : unexpected \")\" : 8 ) : $reply" }

namespace eval a {}
set a::b(4) 5
? { $a::b[4] } 5
