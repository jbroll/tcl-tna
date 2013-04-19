tcl-tna
=======

A numeric array extension for Tcl.

This is a package to do arithmetic on arrays of numbers.  It is similar
to several other packages including:

   * [NAP] : [tcl-nap.sourceforge.net]
   * [narray] : [http://www.ncnr.nist.gov/staff/nickm/narray.html]
   *

TNA is coded in C and Tcl using critcl to glue it into a loadable Tcl package.
It is a follow up to the [Numeric arrays in pure Tcl] prototype.

TNA has these nice features:

   * Data sectioning using ranges.
   * Conversion to and from Tcl list of lists representation.
   * Relativly short code (all in at 2K lines of C and Tcl).
   * Byte compiled to a fully threaded execution engine.


Commands to create arrays and values:

 * tna::array
   Options

     * -index <XYZ|ZYX>
     * -offset x
     * -inclusive yes
     * -ptr  <bare pointer>
     * -data <bytearray>

 * tna::value

Commands to execute expressions:

 * tna::expr	- Compile and execute a tna expression
 * tna::compile - Compile a tna expression, return a list of register, code pairs.
 * tna::execute - Execute a tna list of register, code pairs.
 * tna::disassemble - Conver a list of register, code pairs to pretty text.

Examples:

    package require tna

    tna::array create A double 512 512
    tna::array create B double 512 512
    tna::array create C double 512 512

    tna::expr { A = 1
		B = 4
		    
		C = A * B 
    }

