
package require critcl
package provide typedef 1.0

namespace eval typedef {

    	namespace export typedef
	variable init    0 

    proc typedef { Type version body } {
	package provide $Type $version

	variable init 
	variable name	{}
	variable type	{}
	variable stru	{}
	variable code	{}
	variable decl	{}
	variable tabl	{}
	variable nfields 0
	variable methods {}

	set name ${Type}
	set type ${Type}
	set stru ${Type}_stru

	if { !$init } {
	    critcl::cheaders arec.h
	    critcl::csources arec.c

	    set include {#include "arec.h"}
	} else {
	    set include {}
	}

	set init 1

	eval $body

	puts [set fp [open $name.h w]] "typedef struct $stru {\n$decl } $type;"  ; close $fp

	critcl::ccode [subst {
$include

typedef struct $stru { $decl\n\n } $type;
}]

	critcl::ccode $methods

	critcl::ccode "\t\tARecTypeTable ${name}Table\[] = {\n[join $tabl ,]\t\t};\n"

	critcl::ccode "
	    int ${name}ObjCmd(data, interp, objc, objv, recs, m) 
		ClientData       data;
		Tcl_Interp      *interp;
		int              objc;
		Tcl_Obj        **objv;
		char		*recs;
		int		 m;
	    {
		ARecInst *inst   = (ARecInst *) data;
		Tcl_Obj     *result = Tcl_GetObjResult(interp);

		$code

		return TCL_CONTINUE;
	    }
	"


	critcl::ccode [subst {
	    ARecTypeDef ${name}Type = { "$name", NULL, sizeof($type), $nfields, ${name}Table, ${name}ObjCmd };
	}]
	    
	critcl::ccommand $name { data interp objc objv } [subst -nocommands {
		Tcl_Obj *result = Tcl_GetObjResult(interp);

	    if ( !strcmp("new", Tcl_GetStringFromObj(objv[1], NULL)) ) {
		return ARecNewInst(interp, objc, objv, &${name}Type);
	    }
	    ARecCmd(interp, (&${name}Type), "types", " ?field? ...", objc >= 2, objc, objv,
		return ARecTypeFields(interp, &${name}Type, 1, 0);
	    );
	    ARecCmd(interp, (&${name}Type), "names", " ?field? ...", objc >= 2, objc, objv,
		return ARecTypeFields(interp, &${name}Type, 0, 1);
	    );
	    ARecCmd(interp, (&${name}Type), "fields", " ?field? ...", objc >= 2, objc, objv,
		return ARecTypeFields(interp, &${name}Type, 1, 1);
	    );

	    Tcl_AppendResult(interp, "$name unknown command: ", Tcl_GetStringFromObj(objv[1], NULL), NULL);
	    return TCL_ERROR;
	}]

	::critcl::cinit [subst -nocommands {
	    ARecTypeInit(&${name}Type);
	}] {}
    }

    proc arr-proc { rtype rname params body } { arec-proc $rtype $rname $params $body array  }
    proc rec-proc { rtype rname params body } { arec-proc $rtype $rname $params $body record }

    proc arec-proc { rtype rname params body ptype } {
	variable type
	variable name
	variable code
	variable methods

	set parser {}
	set locals {}

	set ob "{"
	set cb "}"

	set locals "\n\t\t\tint	i;\n\t\t\t$rtype reply;\n"

	switch $rtype {
	    void     { set reply {} }
	    int      { set reply "Tcl_ListObjAppendElement(interp, result,    Tcl_NewIntObj(reply));" }
	    double   { set reply "Tcl_ListObjAppendElement(interp, result, Tcl_NewDoubleObj(reply));" }
	    Tcl_Obj* { set reply "Tcl_ListObjAppendElement(interp, result, reply);" }
	}

	switch $ptype {
	    record {
		set call   "\t\t\tfor ( i = 0; i < m; i++ ) $ob\n\t\t\t\t reply = ${type}_${rname}(($type *) recs"
		set close  ");\n\t\t\t\t$reply\n\t\t\t\trecs += inst->type->size;\n\t\t\t$cb"
	    }
	    array {
		set call   "\t\t\treply = ${type}_${rname}(($type *) &recs\[0], m"
		set close  ");\n"
		set pars   ", int N"
	    }
	}

	set i 2
	foreach { dtype arg } $params {

	     switch $dtype {
		 args {
	     	     append pars ", $dtype $arg"
	     	     append call ", " $arg
		     append call ", objc, objv"
		     append pars ", int objc, Tcl_Obj *objv"
		     append args " ..."
		     break
		 }
		 int	{
	     	     append pars ", $dtype $arg"
	     	     append call ", " $arg
	     	     append locals "\t\t\t$dtype $arg;\n"
		     append parser "\t\t\t   ARecGetIntFromObj(interp, objv\[$i], $arg);\n"
		 }
		 float  -
		 double	{
	     	     append pars ", $dtype $arg"
	     	     append call ", " $arg
	     	     append locals "\t\t\t$dtype $arg;\n"
		     append parser "\t\t\tARecGetDoubleFromObj(interp, objv\[$i], $arg);\n"
		 }
		 default {
	     	     append pars ", $dtype *$arg, int N_$arg"
	     	     append call ", $arg, N_$arg"
	     	     append locals "\t\t\t${dtype} *$arg; int N_$arg;\n"
		     append parser "\t\t\tARecGetARecInstFromObj(interp, objv\[$i], &${dtype}Type, $arg, N_$arg);\n"
		 }
	     }
	     append args  " " $arg
	     incr i
	}

	append call $close

	append code "ARecCmd(interp, inst, \"$rname\", \"$args\", objc >= $i, objc, objv, "
	append code $locals
	append code $parser
	append code $call
	append code "\n\t\t\treturn TCL_OK;"
	append code "\n\t\t);\n"

	append methods "$rtype ${type}_${rname}($type *rec $pars) {\n$body\n}\n\n"
    }

    proc char   { args } { value int    {*}$args }
    proc uchar  { args } { value int    {*}$args }
    proc short  { args } { value int    {*}$args }
    proc ushort { args } { value int    {*}$args }
    proc int    { args } { value int    {*}$args }
    proc float  { args } { value float  {*}$args }
    proc double { args } { value double {*}$args }

    proc char*  { args } { value string {*}$args }

    proc value { dtype args } {
	variable nfields
	variable type
	variable decl
	variable tabl

	foreach value $args {
	    incr nfields

	    set dtype [string map { * Ptr } $dtype]

	    lappend tabl "\t\t\t{ \"$value\", NULL, 0, ARecOff($type *, $value), &ARec[string totitle $dtype]DType }\n"
	     append decl "\t\t$dtype $value;\n"
	}
    }
}
