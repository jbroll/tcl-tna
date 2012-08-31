#!/usr/bin/env tclkit8.6
#

package require tcltest
lappend auto_path ../lib

package require tna


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

puts [d list]
