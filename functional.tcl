
proc iota { fr to { in 1 } } {
    set fr [expr $fr]
    set to [expr $to]
    for { set res {} } { $fr <= $to } { incr fr $in } {lappend res $fr } 
    set res
}
proc map { args } {
    return [uplevel [subst {
        set _[info frame] {}
        foreach [lrange $args 0 end-1] { lappend _[info frame] \[eval {[lindex $args end]}] }
        set _[info frame]
    }]]
}
proc red { args } {
    return [uplevel [subst {
        set _[info frame] {}
        foreach [lrange $args 0 end-1] { set     _[info frame] \[eval {[lindex $args end]}] }
        set _[info frame]
    }]]
}

