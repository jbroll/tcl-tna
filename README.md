tcl-tna
=======

A numeric array extension for Tcl.

This is a package to do arithmetic on arrays of numbers.  It is similar
to several other packages including:

   * [NAP] : [tcl-nap.sourceforge.net]
   * [narray] : [http://www.ncnr.nist.gov/staff/nickm/narray.html]
   * [TArray] : 

TNA is coded in C and Tcl using critcl to glue it into a loadable Tcl package.
It is a follow up to the [Numeric arrays in pure Tcl] prototype on the Tcl Wiki.

TNA has these nice features:

   * Data sectioning using ranges.
   * Conversion to and from Tcl list of lists representation.
   * Relativly short code (all in at 2K lines of C and Tcl).
   * Byte compiled to a fully threaded execution engine.


Commands to create arrays and values:

 * tna::array
   Options

     * -index <XYZ|ZYX>
     * -offset x	(default 0)
     * -inclusive yes	(default no)
     * -ptr  <bare pointer>
     * -data <bytearray>

 * tna::value

Commands to execute expressions:

 * tna::expr	- Compile and execute a tna expression
 * tna::compile - Compile a tna expression, return a list of register, code pairs.
 * tna::execute - Execute a tna list of register, code pairs.
 * tna::disassemble - Convert a list of register, code pairs to pretty text.

Examples:

    package require tna

    tna::array create A double 512 512
    tna::array create B double 512 512
    tna::array create C double 512 512

    tna::expr { A = 1
		B = 4
		    
		C = A * B 
    }


--------------

    package require tna

    tna::array create A double  6 6

    A set {
	{ 1 2 3 }
	{ 4 5 6 }
	{ 7 8 9 }
    }
    puts [join [A list] \n]



