#!/home/john/bin/tclkit8.6
#
 if { 0 } {
  TNA is a class to create and manipulate binary blocks of numbers of up to
  5 dimensions.  The dimensions are named x, y, z, u, v.  The axes are always
  specified in this order, in both creaton commands and indicies.  These data
  types are supported:

	byte, short, ushort, int, uint, long, float, double

  Example creation commands:

    tna create a float 3	; # Create a vector of  3 floating point elements
    tna create b float 3 4	; # Create a matrix of 4 3 vectors.

    puts [b list]
    {0.0 0.0 0.0} {0.0 0.0 0.0} {0.0 0.0 0.0} {0.0 0.0 0.0}


  There are 3 exported methods:

    set index expression

	For each element of the TNA instance indexed by the index, evaluate
	expression and assign the result to that element.

    list

	return the data in list format.

    data

	return the data as a byte array object.


  TNA index syntax

  Indicies appear in two places.  As the second argument to the "set" method and as
  selectors on TNA instances mentioned in the evaluated expression.  As arguments to
  set, they select elements of the instance to be set.  Indicies may be a single
  constant, a range of the form "start:end", or the single character "*".  In a range
  eigher or both of the start and end values may be omitted.  The "*" form is an alias
  for all values of an axis and is the same as ":".  Negative values index in from the
  end.  Indicies for instances with 2 of more dimensions are separated by commas.

  Example set commands and expressons:

     a set * 1		; # set all elements to 1
     a set 1 14		; # set element a(1) to 14

     b set *,* 1	; # set all elements to 1


  TNA set expressions syntax

  The expresson passed to "set" is evaluated by Tcl's internal "expr" command in the 
  current context.  Within the expression the slice position is available in the local
  varaibles $x, $y, $z, $u, and $v.  NB: The slice position is not the same as the element
  index in the underlying instance.  In addition slices of other TNA instances may be
  references by prefixing thier names with "%".

  When indicies are used as selectors in evaluated set expressions the index may also
  contain slice position values and arbitrary expressions.  Slice position values are
  integers designated by the axis names (x, y, z, u, v) and indicate the current position
  in the slice being set.
 }

 lappend auto_path lib

 package require tnaplus

 proc = { title test result } {
    if { $test ne $result } { puts "fail: $title\n$test\n!=\n$result" }
 }

 tna create a short 3 	; = "Simple vector" 	[a list]  {0 0 0}
 tna create b short 3 3	; = "3x3 matrix"	[b list] {{0 0 0} {0 0 0} {0 0 0}}

 a set *      \$x	; = "Vector 0 1 2" 	[a list]  {0 1 2}
 a set *    {$x+1}	; = "Vector 1 2 3" 	[a list]  {1 2 3}
 b set *,1     %a	; = "Full slice" 	[b list] {{0 0 0} {1 2 3} {0 0 0}}
 b set 0:1,*   %a	; = "Short slice"	[b list] {{1 2 0} {1 2 3} {1 2 0}}
 b set *,*     %a	; = "Wrap slice"	[b list] {{1 2 3} {1 2 3} {1 2 3}}
 b set *,*   %a(0:1)	; = "Wrap value"	[b list] {{1 2 1} {1 2 1} {1 2 1}}

 set K 5
 b set *,0     {$K}	; = "Use a local" 	[b list] {{5 5 5} {1 2 1} {1 2 1}}
 b set -1,2	4	; = "minus 1 index" 	[b list] {{5 5 5} {1 2 1} {1 2 4}}

 b set *,*  {$y+$x}	; = "slice indicies"	[b list] {{0 1 2} {1 2 3} {2 3 4}}

 # Go big...
 #
 tna create A double 1024 1024
 tna create B double 1024 1024
 tna create C double 1024 1024

puts [time {A set     *,* { $x + $y }}]
puts [time {B set     *,* { 2 }}]
puts [time {C set     *,* { pow(%A, 2) + pow(%B, 2) + 2*%A*%B }}]
# 652072 microseconds per iteration

