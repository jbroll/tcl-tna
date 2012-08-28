#!/usr/bin/env tclkit8.6
#

lappend auto_path lib

package require tna
source tna-tcl.tcl


tna::array create a double 2048 2048
tna::array create b double 2048 2048
tna::array create c double 2048 2048

tna::expr { a = X+Y }
tna::expr { b = 2 }

foreach i [iota 1 1] {
    tna::expr { c = a*a + b*b + 2.0 * a * b }
}

tna::value create d double 0

tna::expr { d = c[0,0] }
tna::expr { d += c[0:1, 0:1] }

puts [d list]

exit



tna::array create A double 6 6
tna::array create B int    4 4
tna::array create C double 3 3

#tna::expr { C = X*X+X }
#tna::print C

tna::expr { B += D }

tna::print B

exit
tna::expr { C[0,0] = 1 }
tna::expr { C[1,0] = 2 }
tna::expr { C[2,0] = 3 }
tna::expr { C[0,1] = 4 }
tna::expr { C[1,1] = 5 }
tna::expr { C[2,1] = 6 }
tna::expr { C[0,2] = 7 }
tna::expr { C[1,2] = 8 }
tna::expr { C[2,2] = 9 }

tna::expr { C += B + 5 }
tna::expr { A = C }

tna::print [C data] {*}[C dims]
puts ""
tna::print [A data] {*}[A dims]
