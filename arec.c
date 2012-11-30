/* ARec.c

   An array of records is a Tcl data structure which is designed to allow
   the exchange of a large array of structures with lower level C routines
   with very little overhead.  It allows the data to be stored
   in a format that is easily accessed at the C level and does not require
   the low level C routines to continually interact with the Tcl object API.

*/
#include <string.h>

#include <tcl.h>
#include "arec.h"

Tcl_Obj *ARecGetDouble(void *here) { return Tcl_NewDoubleObj(*((double *) here)); }
Tcl_Obj *ARecGetFloat( void *here) { return Tcl_NewDoubleObj(*((float  *) here)); }
Tcl_Obj *ARecGetInt(   void *here) { return Tcl_NewIntObj(   *((int    *) here)); }
Tcl_Obj *ARecGetUShort(void *here) { return Tcl_NewIntObj(   *((unsigned short *) here)); }
Tcl_Obj *ARecGetShort( void *here) { return Tcl_NewIntObj(   *((short  *) here)); }
Tcl_Obj *ARecGetUChar( void *here) { return Tcl_NewIntObj(   *((char   *) here)); }
Tcl_Obj *ARecGetChar(  void *here) { return Tcl_NewIntObj(   *((unsigned char *) here)); }
Tcl_Obj *ARecGetString(void *here) { return Tcl_NewStringObj(*((char  **) here), -1); }


int ARecSetDouble(Tcl_Obj *obj, void *here) { return Tcl_GetDoubleFromObj(NULL, obj, (double *) here); }
int ARecSetFloat( Tcl_Obj *obj, void *here) {
    	double dbl;

    if ( Tcl_GetDoubleFromObj( NULL, obj, &dbl) == TCL_ERROR ) { return TCL_ERROR; }
    *((float *)here) = dbl;

    return TCL_OK;
}
int ARecSetInt(   Tcl_Obj *obj, void *here) { return Tcl_GetIntFromObj(   NULL, obj, (int    *) here); }
int ARecSetUShort(Tcl_Obj *obj, void *here) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((unsigned short *)here) = i;

    return TCL_OK;
}
int ARecSetShort( Tcl_Obj *obj, void *here) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((short *)here) = i;

    return TCL_OK;
}
int ARecSetUChar(Tcl_Obj *obj, void *here) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((unsigned char *)here) = i;

    return TCL_OK;
}
int ARecSetChar(Tcl_Obj *obj, void *here) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((char *)here) = i;

    return TCL_OK;
}
int ARecSetString(Tcl_Obj *obj, void *here) {
    	char *str = *((char **)here);

    if ( str ) { free(str); }

    *(char **) here = strdup(Tcl_GetString(obj));

    return TCL_OK;
}

/* Collect all these structs together to allow introspection.
 */
ARecDType ARecCharDType   = { "char",	sizeof(char)		, ARecSetChar,	ARecGetChar  };
ARecDType ARecUCharDType  = { "uchar",	sizeof(unsigned char)	, ARecSetUChar,	ARecGetUChar };
ARecDType ARecShortDType  = { "short",	sizeof(short)		, ARecSetShort,	ARecGetShort  };
ARecDType ARecUShortDType = { "ushort",	sizeof(unsigned short)	, ARecSetUShort,ARecGetUShort };
ARecDType ARecIntDType	  = { "int",	sizeof(int)		, ARecSetInt,	ARecGetInt    };
ARecDType ARecFloatDType  = { "float",	sizeof(float)		, ARecSetFloat,	ARecGetFloat  };
ARecDType ARecDoubleDType = { "double",	sizeof(double)		, ARecSetDouble,ARecGetDouble };
ARecDType ARecStringDType = { "string",	sizeof(char *)		, ARecSetString,ARecGetString };

ARecDType *ARecDTypes[] = {
    	  &ARecCharDType
	, &ARecUCharDType
	, &ARecShortDType
	, &ARecUShortDType
	, &ARecIntDType
	, &ARecFloatDType
	, &ARecDoubleDType
	, &ARecStringDType
	, NULL
};

ARecDType *ARecLookupDType(Tcl_Obj *nameobj)
{
    char      *name = Tcl_GetString(nameobj);
    ARecDType **dtype;

    for ( dtype = ARecDTypes; *dtype != NULL; dtype++ ) {
	if ( !strcmp((*dtype)->name, name) ) {
	    return *dtype;
	}
    }

    return NULL;
}

ARecTypeTable *ARecLookup(ARecTypeTable *table, Tcl_Obj *nameobj)
{
    char *name = Tcl_GetString(nameobj);

    for ( ; table->nameobj != NULL; table++ ) {
	if ( !strcmp(Tcl_GetString(table->nameobj), name) ) {
	    return table;
	}
    }

    return NULL;
}



int ARecSetField(ARecTypeTable *table, char *record, Tcl_Obj *obj) {
	return table == NULL ? TCL_ERROR : table->dtype->set(obj, record + table->offset);
}

int ARecDelInst(ClientData data)
{
        ARecInst *inst = (ARecInst *) data;

    Tcl_DecrRefCount(inst->nameobj);

    Tcl_Free((void *) inst->recs);
    Tcl_Free((void *) inst);
}

int ARecDelType(ClientData data)
{
    int i;
    ARecTypeDef *type = (ARecTypeDef *) data;

    Tcl_DecrRefCount(type->nameobj);

    for ( i = 0; i < type->nfield; i++ ) { Tcl_DecrRefCount(type->field[i].nameobj); }

    Tcl_Free((void *) type->field);
    Tcl_Free((void *) type);
}


int ARecTypeObjCmd(data, interp, objc, objv)
    ClientData       data;
    Tcl_Interp      *interp;
    int              objc;
    Tcl_Obj        **objv;
{
    ARecTypeDef *type = (ARecTypeDef *) data;
    Tcl_Obj *result = Tcl_GetObjResult(interp);

    if ( !strcmp("new", Tcl_GetString(objv[1])) ) {
	return ARecNewInst(interp, objc, objv, data);
    }
    ARecCmd(interp, type, "types", " ?field? ...", objc >= 2, objc, objv,
	return ARecTypeFields(interp, type, 1, 0);
    );
    ARecCmd(interp, type, "names", " ?field? ...", objc >= 2, objc, objv,
	return ARecTypeFields(interp, type, 0, 1);
    );
    ARecCmd(interp, type, "fields", " ?field? ...", objc >= 2, objc, objv,
	return ARecTypeFields(interp, type, 1, 1);
    );
    ARecCmd(interp, type, "size", "", objc >= 1, objc, objv,
	Tcl_SetObjResult(interp, Tcl_NewIntObj(type->size));	

	return TCL_OK;
    );
    ARecCmd(interp, type, "add-field", " type name", objc >= 4, objc, objv,
	return ARecTypeAddField(interp, type, objc, objv);
    );

    Tcl_AppendResult(interp
	    , Tcl_GetString(type->nameobj)
	    , " unknown command: "
	    , Tcl_GetString(objv[1]), NULL);
    return TCL_ERROR;
}

int ARecNewType(Tcl_Interp *interp, int objc, Tcl_Obj **objv)
{
	Tcl_Obj     *result = Tcl_GetObjResult(interp);
	int	     n = 1;
	ARecTypeDef *type;

    if ( objc != 2 ) {
	Tcl_SetStringObj(result, "NewType type", -1);				\
	return TCL_ERROR;
    }

    type          = (ARecTypeDef *) Tcl_Alloc(sizeof(ARecTypeDef));
    type->nameobj = objv[1];
    Tcl_IncrRefCount(type->nameobj);

    type->size   = 0;
    type->nfield = 0;
    type->afield = 10;
    type->field  = (ARecTypeTable *) Tcl_Alloc(sizeof(ARecTypeTable) * type->afield);
    type->instances = NULL;

    type->field[0].nameobj = NULL;

    Tcl_CreateObjCommand(interp, Tcl_GetString(objv[1])
	, ARecTypeObjCmd
	, (ClientData) type
	, (Tcl_CmdDeleteProc *) ARecDelType);

    Tcl_SetObjResult(interp, objv[1]);	

    return TCL_OK;
}


int ARecInstObjCmd(data, interp, objc, objv)
    ClientData       data;
    Tcl_Interp      *interp;
    int              objc;
    Tcl_Obj        **objv;
{

    Tcl_Obj *result = Tcl_GetObjResult(interp);

    ARecInst *inst = (ARecInst *) data;
    char        *recs = inst->recs;

    int n, m;

    if ( ARecRange(interp, inst, &objc, &objv, &n, &m) == TCL_ERROR ) {
	return TCL_ERROR;
    }
    recs += n * inst->type->size;

    ARecCmd(interp, inst, "set", " field value ...", objc >= 3, objc, objv,
	return ARecSetFromArgs(interp, inst->type, recs, m, objc-2, objv+2);
    );

    ARecCmd(interp, inst, "setdict", " field value ...", objc >= 3, objc, objv,
	return ARecSetFromDict(interp, inst->type, recs, m, objc-2, objv+2);
    );
    ARecCmd(interp, inst, "setlist", " field value ...", objc >= 3, objc, objv,
	return ARecSetFromList(interp, inst->type, recs, m, objc-2, objv+2);
    );

    ARecCmd(interp, inst, "get"    , " ?field? ...", objc >= 2, objc, objv,
	return ARecGet(interp, inst->type, recs, m, 0, objc-2, objv+2);
    );
    ARecCmd(interp, inst, "getdict", " ?field? ...", objc >= 2, objc, objv,
	return ARecGet(interp, inst->type, recs, m, 1, objc-2, objv+2);
    );
    ARecCmd(interp, inst, "getlist", " ?field? ...", objc >= 2, objc, objv,
	return ARecGet(interp, inst->type, recs, m, 0, objc-2, objv+2);
    );
    ARecCmd(interp, inst, "length", " ", objc == 2, objc, objv,
	Tcl_SetIntObj(result, inst->nrecs);
	return TCL_OK;
    );

    ARecCmd(interp, inst, "getbytes", " ", objc == 2, objc, objv,
	Tcl_SetByteArrayObj(result, inst->recs, inst->nrecs * inst->type->size);
	return TCL_OK;
    );
    ARecCmd(interp, inst, "getptr", " ", objc == 2, objc, objv,
	Tcl_SetLongObj(result, (long)inst->recs);
	return TCL_OK;
    );
    ARecCmd(interp, inst, "setbytes", " ", objc == 3, objc, objv,
	int nbytes;
	unsigned char *bytes = Tcl_GetByteArrayFromObj(objv[2], &nbytes);
	memcpy(inst->recs, bytes, nbytes);
	return TCL_OK;
    );

    if ( objc != 1 ) {
	Tcl_AppendResult(interp
		, Tcl_GetString(inst->nameobj)
		, ": unknown command: "
		, Tcl_GetString(objv[1]), "\n", NULL);
    }
    return TCL_ERROR;
}

int ARecNewInst(Tcl_Interp *interp, int objc, Tcl_Obj **objv, ARecTypeDef *type)
{
	Tcl_Obj     *result = Tcl_GetObjResult(interp);
	int	     n = 1;
	ARecInst *inst;

    if ( objc == 4 ) {
	if ( Tcl_GetIntFromObj(interp, objv[3], &n) != TCL_OK  ) {
	    Tcl_SetStringObj(result, "cannot convert size arg to int", -1);				\
	    return TCL_ERROR;
	}
    }

    inst          = (ARecInst *) Tcl_Alloc(sizeof(ARecInst));
    inst->nameobj = objv[2];
    Tcl_IncrRefCount(inst->nameobj);

    inst->type    = type;
    inst->nrecs   = n;
    inst->arecs   = n;
    inst->recs    = Tcl_Alloc(type->size * inst->nrecs);

    memset(inst->recs, 0, type->size * inst->nrecs);

    Tcl_CreateObjCommand(interp, Tcl_GetString(objv[2])
	, ARecInstObjCmd
	, (ClientData) inst
	, (Tcl_CmdDeleteProc *) ARecDelInst);

    Tcl_SetObjResult(interp, objv[2]);	

    inst->next = type->instances;
    type->instances = inst;

    return TCL_OK;
}

int ARecTypeFields(Tcl_Interp *interp, ARecTypeDef *type, int types, int fields)
{
    Tcl_Obj  	 *result = Tcl_GetObjResult(interp);
    int i;

    for ( i = 0; i < type->nfield; i++ ) {
	if ( types  ) Tcl_ListObjAppendElement(interp, result
		    , Tcl_NewStringObj(type->field[i].dtype->name, -1));
	if ( fields ) Tcl_ListObjAppendElement(interp, result, type->field[i].nameobj);
    }

    return TCL_OK;
}

int ARecTypeAddField(Tcl_Interp *interp, ARecTypeDef *type, int objc, Tcl_Obj **objv)
{
    Tcl_Obj  	 *result = Tcl_GetObjResult(interp);
    int i;

    int size = 0;
    int maxx = 0;

    ARecDType *dtype;

    if ( type->instances ) {
	Tcl_AppendStringsToObj(result
		, Tcl_GetString(objv[0])
		, " already has instances"
		, NULL);

	return TCL_ERROR;
    }
    
    if ( !(dtype = ARecLookupDType(objv[2])) ) {
	Tcl_AppendStringsToObj(result
		, Tcl_GetString(objv[0])
		, " unknown data type "
		, NULL);

	return TCL_ERROR;
    }

    maxx = dtype->size;

    for ( i = 0; i < type->nfield; i++ ) {
	size = ARecPadd(size + type->field[i].dtype->size, type->field[i].dtype->size);

	if ( type->field[i].dtype->size > maxx ) {
	    maxx = type->field[i].dtype->size;
	}
    }

    for ( i = 3; i < objc; i++ ) {
	if ( ARecLookup(type->field, objv[i]) ) {
	    Tcl_AppendStringsToObj(result
		    , Tcl_GetString(objv[0])
		    , " already has a field named "
		    , Tcl_GetString(objv[i])
		    , NULL);

	    return TCL_ERROR;
	}

	if ( type->nfield >= type->afield-1 ) {
	    type->afield += 10;
	    type->field = Tcl_Realloc(type->field, sizeof(ARecTypeTable) * type->afield);
	}

	type->field[type->nfield].nameobj = objv[i];
	type->field[type->nfield].offset  = ARecPadd(size, dtype->size);
	type->field[type->nfield].dtype   = dtype;

	size = ARecPadd(size + dtype->size, dtype->size);

	Tcl_IncrRefCount(objv[i]);

	type->nfield++;
	type->field[type->nfield].nameobj = NULL;
    }

    type->size = size;

    return TCL_OK;
}


ARecTypeTable **ARecFieldMap(Tcl_Obj *result
				, int objc
				, Tcl_Obj **objv
				, ARecTypeDef *type
				, int *nmap)
{
    int 	i;
    int		max = objc > type->nfield ? objc : type->nfield;
    ARecTypeTable **map = (ARecTypeTable **) Tcl_Alloc(sizeof(ARecTypeTable *) * max);

    if ( !objc ) {
	for ( i = 0; i < type->nfield; i++ ) {
	    map[i] = &type->field[i];
	}
    } else {
	for ( i = 0; i < objc; i++ ) {
	    if ( !(map[i] = ARecLookup(type->field, objv[i])) ) {
		Tcl_Free(map);

		Tcl_AppendStringsToObj(result
		    , Tcl_GetString(type->nameobj)
		    , " cannot lookup field "
		    , Tcl_GetString(objv[i])
		    , NULL);
		return NULL;
	    }
	}
    }

    if ( !i ) { 
	Tcl_Free(map);

	Tcl_AppendStringsToObj(result
		, Tcl_GetString(type->nameobj)
		, " no fields in this type? "
		, NULL);
	return NULL;
    }

    *nmap = i;
    return map;
}


int ARecIndex(ARecInst *inst, Tcl_Obj *result, int *objc, Tcl_Obj ***objv, int *n) {
	char *here = NULL;

    Tcl_Obj *index = (*objv)[1];

    if ( Tcl_GetIntFromObj(NULL, index, n) == TCL_OK  ) {
	if ( *n >= inst->nrecs ) {						
	    Tcl_AppendStringsToObj(result
		, Tcl_GetString(inst->type->nameobj)
		, " index out of range "
		, Tcl_GetString(index)
		, NULL);
	    return TCL_ERROR;
	}

	(*objc)--;								
	(*objv)++;								
    } else {
	char *end = Tcl_GetString((*objv)[1]);
	char *here = &end[3];

	if ( !strncmp(end, "end", 3) ) {
	    *n = inst->nrecs - 1;
	    if ( end[3] ) {
		*n += strtol(&end[3], &here, 10);
	    }

	    if ( *here ) {
		Tcl_AppendStringsToObj(result
		    , Tcl_GetString(inst->type->nameobj)
		    , " cannot index with "
		    , Tcl_GetString(index)
		    , NULL);

		return TCL_ERROR;
	    }

	    (*objc)--;								
	    (*objv)++;
	}
    }

    return TCL_OK;
}

int ARecRange(Tcl_Interp *interp, ARecInst *inst, int *objc, Tcl_Obj ***objv, int *n, int *m)
{
    Tcl_Obj  	 *result = Tcl_GetObjResult(interp);

    *n = 0;
    *m = 0;


    if ( *objc > 1 && ARecIndex(inst, result, objc, objv, n) != TCL_OK  ) { return TCL_ERROR; }
    *m = *n;								
    if ( *objc > 1 && ARecIndex(inst, result, objc, objv, m) != TCL_OK  ) { return TCL_ERROR; }

    *m = *m - *n + 1;

    return TCL_OK;
}

int ARecSetFromArgs(Tcl_Interp *interp
		     , ARecTypeDef *type
		     , char *recs
		     , int n
		     , int objc
		     , Tcl_Obj **objv)
{
    	int i, j;
	int list = 0;
	Tcl_Obj *result = Tcl_GetObjResult(interp);

    if ( objc % 2 ) {
	return ARecSetFromList(interp, type, recs, n, objc, objv);
    }

    for ( j = 0; j < n; j++ ) {
	for ( i = 0; i < objc; i += 2 ) {
	    ARecTypeTable *field = ARecLookup(type->field, objv[i+0]);

	    if ( !field ) {
		Tcl_AppendStringsToObj(result , Tcl_GetString(type->nameobj) , " field "
			, Tcl_GetString(objv[i+0]), " not defined "
			, NULL);
		return TCL_ERROR;
	    }
	    if ( ARecSetField(field, recs, objv[i+1]) == TCL_ERROR ) {
		Tcl_AppendStringsToObj(result , Tcl_GetString(type->nameobj) , " cannot set field "
			, Tcl_GetString(objv[i+0]), " from "
			, Tcl_GetString(objv[i+1])
			, NULL);
		return TCL_ERROR;
	    }
	}

	recs += type->size;
    }

    return TCL_OK;
}

int ARecSetFromDict(Tcl_Interp *interp
		     , ARecTypeDef *type
		     , char *recs
		     , int n
		     , int objc
		     , Tcl_Obj **objv)
{
    	int i, j;
	Tcl_Obj *result = Tcl_GetObjResult(interp);

	int	  elemc;
	Tcl_Obj	**elemv;

    if ( Tcl_ListObjGetElements(interp, objv[0], &objc, &objv) == TCL_ERROR ) {
	return TCL_ERROR;
    }

    for ( j = 0; j < n; j++ ) {
	if ( Tcl_ListObjGetElements(interp, objv[j % objc], &elemc, &elemv) == TCL_ERROR ) {
	    return TCL_ERROR;
	}

        if ( elemc % 2 ) {
	    Tcl_AppendStringsToObj(result
		    , Tcl_GetString(type->nameobj) , " cannot set fields from an odd number of elements"
		    , NULL);
	    return TCL_ERROR;
	}

	for ( i = 0; i < elemc; i += 2 ) {
	    if ( ARecSetField(ARecLookup(type->field, elemv[i+0]), recs, elemv[i+1]) == TCL_ERROR ) {
		Tcl_AppendStringsToObj(result
			, Tcl_GetString(type->nameobj)
			, " cannot set field "
			, Tcl_GetString(elemv[i+0]), " from "
			, Tcl_GetString(elemv[i+1])
			, NULL);
		return TCL_ERROR;
	    }
	}

	recs += type->size;
    }

    return TCL_OK;
}

int ARecSetFromList(Tcl_Interp *interp
		     , ARecTypeDef *type
		     , char *inst
		     , int n
		     , int objc
		     , Tcl_Obj **objv)
{
	ARecTypeTable *table = type->field;
	Tcl_Obj  	 *result = Tcl_GetObjResult(interp);

        ARecTypeTable **map;
	int		  nmap;
	int		 j, i, m;

	int	  elemc;
	Tcl_Obj	**elemv;
	int	  incr = 0;

    if ( !objc ) {
	Tcl_AppendStringsToObj(result , Tcl_GetString(type->nameobj) , " too few args to setlist " , NULL);
	return TCL_ERROR;
    }
    if ( !(map = ARecFieldMap(result, objc - 1, objv, type, &nmap)) ) {
	return TCL_ERROR;
    }

    if ( Tcl_ListObjGetElements(interp, objv[objc - 1], &objc, &objv) == TCL_ERROR ) {
	Tcl_Free((void *) map);
	return TCL_ERROR;
    }

    for ( j = 0; j < n; j++ ) {
	if ( Tcl_ListObjGetElements(interp, objv[j % objc], &elemc, &elemv) == TCL_ERROR ) {
	    Tcl_Free((void *) map);
	    return TCL_ERROR;
	}

	for ( i = 0, m = 0; i < elemc && m < nmap; i++, m++ ) {
	    if ( ARecSetField(map[m], inst, elemv[i]) == TCL_ERROR ) {
		Tcl_AppendStringsToObj(result, Tcl_GetString(type->nameobj), " cannot set field "
		    , Tcl_GetString(map[m]->nameobj), " of type ", map[m]->dtype->name, " from " , Tcl_GetString(elemv[i]),
		    NULL);

		Tcl_Free((void *) map);
		return TCL_ERROR;
	    }
	}

	inst += type->size;
    }

    Tcl_Free((void *) map);
    return TCL_OK;
}

int ARecGet(Tcl_Interp *interp
		  , ARecTypeDef *type
		  , char *recs
		  , int n
		  , int asdict
		  , int objc
		  , Tcl_Obj **objv)
{
    	int i, j;

	Tcl_Obj *result = Tcl_GetObjResult(interp);
        ARecTypeTable **map;
	int		  nmap;
	
    if ( !(map = ARecFieldMap(result, objc, objv, type, &nmap)) ) {
	return TCL_ERROR;
    }

    for ( j = 0; j < n; j++ ) {
	    	Tcl_Obj *reply = Tcl_NewObj();

	for ( i = 0 ; i < nmap; i++ ) {
	    if ( asdict ) {
		if ( Tcl_ListObjAppendElement(interp, reply, map[i]->nameobj) == TCL_ERROR ) {
		    Tcl_Free((void *) map);
		    return TCL_ERROR;
		}
	    }

	    if ( Tcl_ListObjAppendElement(interp, reply, map[i]->dtype->get(recs + map[i]->offset)) == TCL_ERROR ) {
		Tcl_Free((void *) map);
		return TCL_ERROR;
	    }
	}
	if ( Tcl_ListObjAppendElement(interp, result, reply) == TCL_ERROR ) {
	    Tcl_Free((void *) map);
	    return TCL_ERROR;
	}

	recs += type->size;
    }

    Tcl_Free((void *) map);
    return TCL_OK;
}

