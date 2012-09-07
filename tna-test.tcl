#!/usr/bin/env tclkit8.6
#

package require tcltest

package require tcltest
lappend auto_path lib

package require tna

tna::nthread 2

cd [file dirname [file normalize [info script]]]/test

::tcltest::configure -testdir [file dirname [file normalize [info script]]] -singleproc 1

::tcltest::configure {*}$argv
::tcltest::runAllTests

