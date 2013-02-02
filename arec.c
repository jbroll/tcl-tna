/* ARec.c

   An array of records is a Tcl data structure which is designed to allow
   the exchange of a large array of structures with lower level C routines
   with very little overhead.  It allows the data to be stored
   in a format that is easily accessed at the C level and does not require
   the low level C routines to continually interact with the Tcl object API.

*/
#include <string.h>
#include <stdlib.h>
#include <stddef.h>

#include <tcl.h>
#include "arec.h"

Tcl_Obj *ARecGetDouble(ARecTypeTable *type, void *here) { return Tcl_NewDoubleObj(*((double *) here)); }
Tcl_Obj *ARecGetFloat( ARecTypeTable *type, void *here) { return Tcl_NewDoubleObj(*((float  *) here)); }
Tcl_Obj *ARecGetLong(  ARecTypeTable *type, void *here) { return Tcl_NewLongObj(  *((long   *) here)); }
Tcl_Obj *ARecGetInt(   ARecTypeTable *type, void *here) { return Tcl_NewIntObj(   *((int    *) here)); }
Tcl_Obj *ARecGetUShort(ARecTypeTable *type, void *here) { return Tcl_NewIntObj(   *((unsigned short *) here)); }
Tcl_Obj *ARecGetShort( ARecTypeTable *type, void *here) { return Tcl_NewIntObj(   *((short  *) here)); }
Tcl_Obj *ARecGetUChar( ARecTypeTable *type, void *here) { return Tcl_NewIntObj(   *((char   *) here)); }
Tcl_Obj *ARecGetChar(  ARecTypeTable *type, void *here) { return Tcl_NewIntObj(   *((unsigned char *) here)); }
Tcl_Obj *ARecGetString(ARecTypeTable *type, void *here) { return Tcl_NewStringObj(*((char  **) here), -1); }


int ARecSetDouble(ARecTypeTable *type, Tcl_Obj *obj, void *here) { return Tcl_GetDoubleFromObj(NULL, obj, (double *) here); }
int ARecSetFloat( ARecTypeTable *type, Tcl_Obj *obj, void *here) {
    	double dbl;

    if ( Tcl_GetDoubleFromObj( NULL, obj, &dbl) == TCL_ERROR ) { return TCL_ERROR; }
    *((float *)here) = dbl;

    return TCL_OK;
}
int ARecSetLong(  ARecTypeTable *type, Tcl_Obj *obj, void *here) { return Tcl_GetLongFromObj(  NULL, obj, (long   *) here); }
int ARecSetInt(   ARecTypeTable *type, Tcl_Obj *obj, void *here) { return Tcl_GetIntFromObj(   NULL, obj, (int    *) here); }
int ARecSetUShort(ARecTypeTable *type, Tcl_Obj *obj, void *here) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((unsigned short *)here) = i;

    return TCL_OK;
}
int ARecSetShort( ARecTypeTable *type, Tcl_Obj *obj, void *here) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((short *)here) = i;

    return TCL_OK;
}
int ARecSetUChar(ARecTypeTable *type, Tcl_Obj *obj, void *here) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((unsigned char *)here) = i;

    return TCL_OK;
}
int ARecSetChar(ARecTypeTable *type, Tcl_Obj *obj, void *here) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((char *)here) = i;

    return TCL_OK;
}
int ARecSetString(ARecTypeTable *type, Tcl_Obj *obj, void *here) {
    	char *str = *((char **)here);

    if ( str ) { free((void *) str); }

    *(char **) here = strdup(Tcl_GetString(obj));

    return TCL_OK;
}


	/* Collect all these structs together to allow introspection.
	 */
	ARecDType ARecDTypes[] = {
		  { "char",	sizeof(char)		, 1, NULL, ARecSetChar,		ARecGetChar   }
		, { "uchar",	sizeof(unsigned char)	, 1, NULL, ARecSetUChar,	ARecGetUChar  }
		, { "short",	sizeof(short)		, 2, NULL, ARecSetShort,	ARecGetShort  }
		, { "ushort",	sizeof(unsigned short)	, 2, NULL, ARecSetUShort,	ARecGetUShort }
		, { "int",	sizeof(int)		, 4, NULL, ARecSetInt,		ARecGetInt    }
		, { "long",	sizeof(long)		, 4, NULL, ARecSetLong,		ARecGetLong    }
		, { "float",	sizeof(float)		, 4, NULL, ARecSetFloat,	ARecGetFloat  }
		, { "double",	sizeof(double)		, 4, NULL, ARecSetDouble,	ARecGetDouble }
		, { "string",	sizeof(char *)		, 4, NULL, ARecSetString,	ARecGetString }
		, { NULL }
	};

	ARecTypeTable ARecDTypesTypeTable[] = {
	      { (Tcl_Obj *) "name",  offsetof(ARecDType, name),  &ARecDTypes[8] }
	    , { (Tcl_Obj *) "size",  offsetof(ARecDType, size),  &ARecDTypes[4] }
	    , { (Tcl_Obj *) "align", offsetof(ARecDType, align), &ARecDTypes[4] }
	};

	ARecType ARecDTypesType = {
		  (Tcl_Obj *) "dtype"
		, sizeof(ARecDType)
		, sizeof(ARecDTypesTypeTable)/sizeof(ARecTypeTable), 0
		, ARecDTypesTypeTable
		, NULL
	};

	ARecInst ARecDTypesInst = {
		  (Tcl_Obj *) "dtypes"
		, &ARecDTypesType, NULL
		, ARecDTypes 
		, sizeof(ARecDTypes)/sizeof(ARecDType)-1, 0
	};
		

	ARecDType *ARecLookupDType(Tcl_Obj *nameobj)
	{
	    char      *name = Tcl_GetString(nameobj);
	    ARecDType *dtype;

	    for ( dtype = ARecDTypes; dtype->name != NULL; dtype++ ) {
		if ( !strcmp(dtype->name, name) ) {
		    return dtype;
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
	return table == NULL ? TCL_ERROR : table->dtype->set(table->dtype->type, obj, record + table->offset);
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
    ARecType *type = (ARecType *) data;

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
    ARecType *type = (ARecType *) data;
    Tcl_Obj *result = Tcl_GetObjResult(interp);

    ARecCmd(interp, type, "new", " ?inst? ...", objc >= 3, objc, objv,
	return ARecNewInst(interp, objc, objv, data);
    );
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

    ARecUnknownMethod(interp, type, objc, objv);

    return TCL_ERROR;
}

int ARecNewType(Tcl_Interp *interp, int objc, Tcl_Obj **objv)
{
	Tcl_Obj     *result = Tcl_GetObjResult(interp);
	int	     n = 1;
	ARecType *type;

    if ( objc != 2 ) {
	Tcl_SetStringObj(result, "NewType type", -1);				\
	return TCL_ERROR;
    }

    type          = (ARecType *) Tcl_Alloc(sizeof(ARecType));
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
    char        *recs;

    int n, m;

    ARecCmd(interp, inst, "length", " ", objc == 2 || objc == 3, objc, objv,
	int n;

	if ( objc == 3 ) {
	    if ( Tcl_GetIntFromObj(interp, objv[2], &n) != TCL_OK  ) { return TCL_ERROR; }

	    ARecRealloc(inst, n, 0);
	}

	Tcl_SetIntObj(result, inst->nrecs);

	return TCL_OK;
    );

    if ( ARecRange(interp, inst, &objc, &objv, &n, &m) == TCL_ERROR ) {		// All commands below here allow ranges.
	return TCL_ERROR;
    }

    if ( n+m-1 < 0 || n+m-1 > inst->nrecs )  {
	char index[50];
	sprintf(index, "%d %d", n, m);

	Tcl_AppendStringsToObj(result, Tcl_GetString(inst->type->nameobj), " index out of range ", index, NULL);

	return TCL_ERROR;
    }

    ARecCmd(interp, inst, "set", " field value ...", objc >= 3, objc, objv,
	if ( n+m-1 == inst->nrecs ) { ARecRealloc(inst, n+m, 10); }

	recs = inst->recs + n * inst->type->size;

	return ARecSetFromArgs(interp, inst->type, recs, m, objc-2, objv+2);
    );

    ARecCmd(interp, inst, "setdict", " field value ...", objc >= 3, objc, objv,
	if ( n+m-1 == inst->nrecs ) { ARecRealloc(inst, n+m, 10); }

	recs = inst->recs + n * inst->type->size;

	return ARecSetFromDict(interp, inst->type, recs, m, objc-2, objv+2);
    );
    ARecCmd(interp, inst, "setlist", " field value ...", objc >= 3, objc, objv,
	if ( n+m-1 == inst->nrecs ) { ARecRealloc(inst, n+m, 10); }

	recs = inst->recs + n * inst->type->size;

	return ARecSetFromList(interp, inst->type, recs, m, objc-2, objv+2);
    );


    if ( n + m-1 >= inst->nrecs ) {						// All commands below here do not allow extension
	char index[50];
	sprintf(index, "%d %d", n, m);

	Tcl_AppendStringsToObj(result , Tcl_GetString(inst->type->nameobj), " index out of range ", index, NULL);
	
	return TCL_ERROR;
    }

    recs = inst->recs + n * inst->type->size;

    ARecCmd(interp, inst, "get"    , " ?field? ...", objc >= 2, objc, objv,
	return ARecGet(interp, inst->type, recs, m, 0, objc-2, objv+2);
    );
    ARecCmd(interp, inst, "getlist", " ?field? ...", objc >= 2, objc, objv,
	return ARecGet(interp, inst->type, recs, m, 0, objc-2, objv+2);
    );
    ARecCmd(interp, inst, "getdict", " ?field? ...", objc >= 2, objc, objv,
	return ARecGet(interp, inst->type, recs, m, 1, objc-2, objv+2);
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

    ARecUnknownMethod(interp, inst, objc, objv);

    return TCL_ERROR;
}

int ARecNewInst(Tcl_Interp *interp, int objc, Tcl_Obj **objv, ARecType *type)
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

int ARecTypeFields(Tcl_Interp *interp, ARecType *type, int types, int fields)
{
    Tcl_Obj  	 *result = Tcl_NewObj();
    int i;

    for ( i = 0; i < type->nfield; i++ ) {
	if ( types  ) { Tcl_ListObjAppendElement(interp, result , Tcl_NewStringObj(type->field[i].dtype->name, -1)); }
	if ( fields ) { Tcl_ListObjAppendElement(interp, result, type->field[i].nameobj); }
    }

    Tcl_SetObjResult(interp, result);

    return TCL_OK;
}

int ARecTypeAddField(Tcl_Interp *interp, ARecType *type, int objc, Tcl_Obj **objv)
{
    Tcl_Obj  	 *result = Tcl_GetObjResult(interp);
    int i;

    int size = 0;
    int maxx;

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

    maxx = dtype->align;

    for ( i = 0; i < type->nfield; i++ ) {
	size = ARecPadd(size + type->field[i].dtype->size, type->field[i].dtype->align);

	if ( type->field[i].dtype->align > maxx ) {
	    maxx = type->field[i].dtype->align;
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
	    type->field = (ARecTypeTable *) Tcl_Realloc((char *) type->field, sizeof(ARecTypeTable) * type->afield);
	}

	type->field[type->nfield].nameobj = objv[i];
	Tcl_IncrRefCount(objv[i]);

	type->field[type->nfield].offset  = ARecPadd(size, dtype->align);
	type->field[type->nfield].dtype   = dtype;

	size = ARecPadd(size + dtype->size, dtype->align);

	type->nfield++;
	type->field[type->nfield].nameobj = NULL;
    }

    type->size = ARecPadd(size, maxx);

    return TCL_OK;
}


ARecTypeTable **ARecFieldMap(Tcl_Obj *result
				, int objc
				, Tcl_Obj **objv
				, ARecType *type
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
		Tcl_Free((char *) map);

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
	Tcl_Free((char *) map);

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

ARecRealloc(ARecInst *inst, int nrecs, int more) 
{
    if ( nrecs >  inst->arecs ) {
	inst->arecs = nrecs + more;

	inst->recs = Tcl_Realloc((char *) inst->recs, inst->arecs * inst->type->size);

	memset(&((char *)inst->recs)[inst->nrecs * inst->type->size], 0, inst->type->size * more);
    }
    inst->nrecs = nrecs;
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
		     , ARecType *type
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
		     , ARecType *type
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
		     , ARecType *type
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
		  , ARecType *type
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

	    if ( Tcl_ListObjAppendElement(interp, reply, map[i]->dtype->get(map[i]->dtype->type, recs + map[i]->offset)) == TCL_ERROR ) {
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


typedef struct _LngAlign {
	long	x;
	char	y;
} LngAlign;

typedef struct _DblAlign {
	double	x;
	char	y;
} DblAlign;


void ARecInit(Tcl_Interp *ip) {
    ARecDType *dtype;
    int i;

    ARecDTypesType.nameobj = Tcl_NewStringObj((char *)ARecDTypesType.nameobj, -1);
    Tcl_IncrRefCount(ARecDTypesType.nameobj);
    ARecDTypesInst.nameobj = Tcl_NewStringObj((char *)ARecDTypesInst.nameobj, -1);
    Tcl_IncrRefCount(ARecDTypesInst.nameobj);

    for ( i = 0 ; i < ARecDTypesType.nfield; i++ ) {
	ARecDTypesType.field[i].nameobj = Tcl_NewStringObj((char *)ARecDTypesType.field[i].nameobj, -1);
	Tcl_IncrRefCount(ARecDTypesType.field[i].nameobj);
    }

    for ( dtype = ARecDTypes; dtype->name != NULL; dtype++ ) {
	if ( !strcmp(dtype->name, "double") ) { dtype->align = sizeof(DblAlign) - sizeof(double); }
	if ( !strcmp(dtype->name, "long")   ) { dtype->align = sizeof(LngAlign) - sizeof(long); }
    }

    Tcl_CreateObjCommand(
	  ip
	, "arec::dtype"
	, ARecTypeObjCmd
	, (ClientData) &ARecDTypesType
	, (Tcl_CmdDeleteProc *) ARecDelType);

    Tcl_CreateObjCommand(
	  ip
	, "arec::dtypes"
	, ARecInstObjCmd
	, (ClientData) &ARecDTypesInst
	, (Tcl_CmdDeleteProc *) ARecDelInst);
}

