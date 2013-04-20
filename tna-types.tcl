
namespace eval tna {
    set debug    0

    set regsize 512

    set  Axes { X Y Z U V }		; # The names of the axis index variables
    set nAxes [llength $Axes]

    # This array defines the types available in the package.
    #
    #       tnaType CType         	pType	pFmt	getType	getFunc			scan
    set Types {
	      char  char              	int     %d 	int	Tcl_GetIntFromObj	c
	     uchar "unsigned char"    	int     %d 	int	Tcl_GetIntFromObj	c 
	     short  short		int     %d 	int	Tcl_GetIntFromObj	s 
	    ushort "unsigned short"	int     %d 	int	Tcl_GetIntFromObj	s 
	       int  int 		int     %d 	int	Tcl_GetIntFromObj	i
	      uint "unsigned int"	long    %u 	long	Tcl_GetLongFromObj	i 
	      long "long"		long   %ld 	long	Tcl_GetLongFromObj	i 
	     ulong "unsigned long"	long   %lu 	long	Tcl_GetLongFromObj	i
	     float  float		double  %f 	double	Tcl_GetDoubleFromObj	f 
	    double  double		double  %f 	double	Tcl_GetDoubleFromObj	d 
    }
}

