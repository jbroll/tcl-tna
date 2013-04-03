
#define Max(x, y)	((x>y) ? (x) : (y))

#define	AREC_ISLIST	1
#define AREC_ASDICT	2

#define ARecPadd(offset, align) ((offset + align - 1) & ~(align - 1))

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


typedef struct _ARecType *ARecTypePtr;		// This is strange!

typedef int       (*ARecSetFunc)(Tcl_Interp *ip, ARecTypePtr type, Tcl_Obj *, void *, int m, int objc, Tcl_Obj** objv, int flags);
typedef Tcl_Obj*  (*ARecGetFunc)(Tcl_Interp *ip, ARecTypePtr type,            void *, int m, int objc, Tcl_Obj** objv, int flags);

typedef struct _ARecType {
    Tcl_Obj		*nameobj;
    int		  	 size;
    int		 	 align;

    int		 	nfield;
    int		 	afield;
    struct _ARecField   *field;

    ARecSetFunc	set;
    ARecGetFunc	get;

    struct _ARecType 	*shadow;
    struct _ARecField 	*instances;
} ARecType;

typedef struct _ARecField {
    Tcl_Obj		*nameobj;
    ARecType		*type;
    void		*recs;
    int	 	 	 offset;
    int			 nrecs;
    int			 arecs;
} ARecField;

Tcl_Obj *ARecGetDouble(Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags);
Tcl_Obj *ARecGetFloat( Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags);
Tcl_Obj *ARecGetInt(   Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags);

int ARecSetDouble(Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags);
int ARecSetFloat( Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags);
int ARecSetInt(   Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags);

int ARecNewInst(Tcl_Interp *interp, int objc, Tcl_Obj **objv, ARecType *type);
int ARecSetFromArgs(Tcl_Interp *interp, ARecType *type, char *recs, int m, int objc, Tcl_Obj **objv, int flags);
int ARecSetFromList(Tcl_Interp *interp, ARecType *type, char *recs, int m, int objc, Tcl_Obj **objv, int flags);
int ARecSetFromDict(Tcl_Interp *interp, ARecType *type, char *recs, int m, int objc, Tcl_Obj **objv, int flags);

ARecType *ARecTypeAddType(ARecField *types, Tcl_Obj *nameobj, int size, int align, ARecSetFunc set, ARecGetFunc get);

Tcl_Obj *ARecGetStruct(Tcl_Interp *ip, ARecType *type, void *recs, int m, int objc, Tcl_Obj **objv, int flags);

ARecType *ARecLookupType(Tcl_Obj *nameobj);

typedef char *string;

ARecField *ARecCreateType(Tcl_Obj *name);

