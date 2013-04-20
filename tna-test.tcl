#!/usr/bin/env tclkit8.6
#

package require tcltest

lappend auto_path lib ../lib arec/lib ../arec/lib

package require nproc
package require arec
package require tna

tna::nthread [nproc]

cd [file dirname [file normalize [info script]]]/test

::tcltest::configure -testdir [file dirname [file normalize [info script]]] -singleproc 1

::tcltest::configure {*}$argv
::tcltest::runAllTests

