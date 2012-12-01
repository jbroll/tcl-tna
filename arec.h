

#define ARecPadd(offset, align) ((offset + align - 1) & ~(align - 1))

#define ARecOff(p_type,field) \
            ((int) (((char *) (&(((p_type)NULL)->field))) - ((char *) NULL)))

#define ARecCmd(interp, inst, name, args, expr, objc, objv, code)	\
    if ( objc == 1 )							\
    	    Tcl_AppendStringsToObj(result, "	",  Tcl_GetString(inst->nameobj), " ", name, " ", args, "\n", NULL); \
    else								\
    if ( !strcmp(name, Tcl_GetStringFromObj(objv[1], NULL)) ) {		\
	if ( !(expr) ) { 						\
    	    Tcl_AppendStringsToObj(result, "	",  Tcl_GetString(inst->nameobj), " ", name, " ", args, "\n", NULL); \
	    return TCL_ERROR;						\
	} else {							\
	    code							\
	}								\
    }

#define ARecUnknownMethod(interp, inst, objc, objv)			\
    Tcl_AppendResult(interp						\
	    , Tcl_GetString(inst->nameobj)				\
	    , objc == 1 ? " no method?" : " unknown method: "		\
	    , objc == 1 ? NULL         : Tcl_GetString(objv[1]), NULL);


#define ARecGetIntFromObj(interp, obj, name)					\
	if ( Tcl_GetIntFromObj(interp, obj, &name) != TCL_OK ) {		\
	    Tcl_SetStringObj(result, "cannot convert " #name " to int", -1);	\
	    return TCL_ERROR;							\
	}

#define ARecGetDoubleFromObj(interp, obj, name)					\
	if ( Tcl_GetDoubleFromObj(interp, obj, &name) != TCL_OK ) {		\
	    Tcl_SetStringObj(result, "cannot convert " #name " to double", -1);	\
	    return TCL_ERROR;							\
	}

#define ARecGetARecInstFromObj(interp, obj, type, name, count)				\
	if ( Tcl_GetARecInstFromObj(interp, obj, type, &name, &count) != TCL_OK ) {	\
	    Tcl_SetStringObj(result, "cannot convert " #name " to arec instance", -1);	\
	    return TCL_ERROR;								\
	}


typedef struct _ARecDType {
    char	*name;
    int		 size;
    int		 align;
    int		(*set)(Tcl_Obj *, void *);
    Tcl_Obj*	(*get)(void *);
} ARecDType;

typedef struct _ARecTypeTable {
    Tcl_Obj		*nameobj;
    int	 	 	 offset;
    ARecDType		*dtype;
} ARecTypeTable;

typedef struct _ARecType {
    Tcl_Obj	     *nameobj;
    int		      size;
    int		     nfield;
    int		     afield;
    ARecTypeTable   *field;
    struct _ARecInst    *instances;
} ARecType;

typedef struct _ARecInst {
    Tcl_Obj	*nameobj;
    ARecType	*type;
    struct _ARecInst	*next;
    void		*recs;
    int			nrecs;
    int			arecs;
} ARecInst;

Tcl_Obj *ARecGetDouble(void *here);
Tcl_Obj *ARecGetFloat( void *here);
Tcl_Obj *ARecGetInt(   void *here);

int ARecSetDouble(Tcl_Obj *obj, void *here);
int ARecSetFloat( Tcl_Obj *obj, void *here);
int ARecSetInt(   Tcl_Obj *obj, void *here);

int ARecNewInst(Tcl_Interp *interp, int objc, Tcl_Obj **objv, ARecType *type);
int ARecSetFromArgs(Tcl_Interp *interp
		     , ARecType *type
		     , char *recs
		     , int n
		     , int objc
		     , Tcl_Obj **objv);
int ARecSetFromList(Tcl_Interp *interp
		     , ARecType *type
		     , char *recs
		     , int n
		     , int objc
		     , Tcl_Obj **objv);
int ARecSetFromDict(Tcl_Interp *interp
		     , ARecType *type
		     , char *recs
		     , int n
		     , int objc
		     , Tcl_Obj **objv);

ARecDType *ARecLookupDType(Tcl_Obj *nameobj);

typedef char *string;
