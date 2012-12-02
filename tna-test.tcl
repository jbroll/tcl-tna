#!/usr/bin/env tclkit8.6
#

package require tcltest

lappend auto_path lib ../lib

package require tna
package require arec
package require nproc

tna::nthread [nproc]

cd [file dirname [file normalize [info script]]]/test

::tcltest::configure -testdir [file dirname [file normalize [info script]]] -singleproc 1

::tcltest::configure {*}$argv
::tcltest::runAllTests

