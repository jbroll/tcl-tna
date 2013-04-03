/* ARec.c

   An array of records is a Tcl data structure which is designed to allow
   the exchange of an array of structures with lower level C routines
   with very little overhead.  It allows the data to be stored
   in a format that is easily accessed at the C level and does not require
   the low level C routines to continually interact with the Tcl object API.

*/
#include <string.h>
#include <stdlib.h>
#include <stddef.h>

#include <tcl.h>
#include "arec.h"

ARecType  *ARecTypeType = NULL;
ARecField *ARecTypeInst = NULL;
#define   ARecTypeTypes ((ARecType *) ARecTypeInst->recs)

Tcl_Obj *ARecGetDouble(Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return Tcl_NewDoubleObj(*((double *) here)); }
Tcl_Obj *ARecGetFloat( Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return Tcl_NewDoubleObj(*((float  *) here)); }
Tcl_Obj *ARecGetLong(  Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return Tcl_NewLongObj(  *((long   *) here)); }
Tcl_Obj *ARecGetInt(   Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return Tcl_NewIntObj(   *((int    *) here)); }
Tcl_Obj *ARecGetUShort(Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return Tcl_NewIntObj(   *((unsigned short *) here)); }
Tcl_Obj *ARecGetShort( Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return Tcl_NewIntObj(   *((short  *) here)); }
Tcl_Obj *ARecGetUChar( Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return Tcl_NewIntObj(   *((char   *) here)); }
Tcl_Obj *ARecGetChar(  Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return Tcl_NewIntObj(   *((unsigned char *) here)); }
Tcl_Obj *ARecGetString(Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return Tcl_NewStringObj(*((char  **) here), -1); }
Tcl_Obj *ARecGetTclObj(Tcl_Interp *ip, ARecType *type, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return *((Tcl_Obj  **) here); }

int ARecSetDouble(Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return Tcl_GetDoubleFromObj(NULL, obj, (double *) here); }
int ARecSetFloat( Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags) {
    	double dbl;

    if ( Tcl_GetDoubleFromObj( NULL, obj, &dbl) == TCL_ERROR ) { return TCL_ERROR; }
    *((float *)here) = dbl;

    return TCL_OK;
}
int ARecSetLong(  Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags) { return Tcl_GetLongFromObj(  NULL, obj, (long   *) here); }
int ARecSetInt(   Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags) {
    double value;

    int ret = Tcl_GetDoubleFromObj(NULL, obj, &value);
    *((int    *) here) = (int) value;

    return ret;
}
int ARecSetUShort(Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((unsigned short *)here) = i;

    return TCL_OK;
}
int ARecSetShort( Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((short *)here) = i;

    return TCL_OK;
}
int ARecSetUChar(Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((unsigned char *)here) = i;

    return TCL_OK;
}
int ARecSetChar(Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags) {
    	int i;

    if ( Tcl_GetIntFromObj( NULL, obj, &i) == TCL_ERROR ) { return TCL_ERROR; }
    *((char *)here) = i;

    return TCL_OK;
}
int ARecSetString(Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags) {
    	char *str = *((char **)here);

    if ( str ) {  free((void *) str); }

    *(char **) here = strdup(Tcl_GetString(obj));

    return TCL_OK;
}
int ARecSetStruct(Tcl_Interp *ip, ARecType *type, Tcl_Obj *obj, void *here, int m, int objc, Tcl_Obj** objv, int flags) {

    return TCL_OK;
}

ARecType *ARecLookupType(Tcl_Obj *nameobj)
{
    ARecType *table = ARecTypeTypes;
    int i;

    char *name = Tcl_GetString(nameobj);

    ARecType *types = ARecTypeInst->recs;

    for ( i = 0; i < ARecTypeInst->nrecs; i++ ) {
	if ( !strcmp(Tcl_GetString(types[i].nameobj), name) ) {

	    return types[i].shadow;
	}
    }

    return NULL;
}

ARecField *ARecLookupField(int n, ARecField *table, Tcl_Obj *nameobj)
{
    char *name = Tcl_GetString(nameobj);

    for ( ; n--; table++ ) {
	if ( !strcmp(Tcl_GetString(table->nameobj), name) ) {
	    return table;
	}
    }

    return NULL;
}

int ARecSetField(Tcl_Interp *ip, ARecField *table, char *record, Tcl_Obj *obj) {
	return table == NULL ? TCL_ERROR : table->type->set(ip, table->type, obj, record + table->offset, 0, 0, NULL, 0);
}

int ARecDelInst(ClientData data)
{
        ARecField *inst = (ARecField *) data;

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

int ARecTypeObjCmd(data, ip, objc, objv)
    ClientData       data;
    Tcl_Interp      *ip;
    int              objc;
    Tcl_Obj        **objv;
{
    ARecType *type = (ARecType *) data;
    Tcl_Obj *result = Tcl_GetObjResult(ip);

    ARecCmd(ip, type, "create", " ?inst? ...", objc >= 3, objc, objv,
	return ARecNewInst(ip, objc, objv, data);
    );
    ARecCmd(ip, type, "size", "", objc >= 1, objc, objv,
	Tcl_SetObjResult(ip, Tcl_NewIntObj(type->size));	

	return TCL_OK;
    );

    ARecCmd(ip, type, "types",   " ?field? ...", objc >= 2, objc, objv, return ARecTypeFields(ip, type, 1, 0, 0););
    ARecCmd(ip, type, "names",   " ?field? ...", objc >= 2, objc, objv, return ARecTypeFields(ip, type, 0, 1, 0););
    ARecCmd(ip, type, "fields",  " ?field? ...", objc >= 2, objc, objv, return ARecTypeFields(ip, type, 1, 1, 0););
    ARecCmd(ip, type, "offsets", " ?field? ...", objc >= 2, objc, objv, return ARecTypeFields(ip, type, 1, 1, 1););

    ARecCmd(ip, type, "add-field", " type name", objc >= 4, objc, objv,
	return ARecTypeAddField(ip, type, objc, objv);
    );

    ARecUnknownMethod(ip, type, objc, objv);

    return TCL_ERROR;
}

ARecType *ARecTypeCreate(Tcl_Interp *ip, Tcl_Obj *name)
{
    ARecType *type = ARecTypeAddType(ARecTypeInst, name, 0, 1, ARecSetStruct, ARecGetStruct);

    Tcl_CreateObjCommand(ip, Tcl_GetString(name)
	, ARecTypeObjCmd
	, (ClientData) type->shadow
	, (Tcl_CmdDeleteProc *) ARecDelType);

    return type->shadow;
}

int ARecTypeCreateObjCmd(Tcl_Interp *ip, int objc, Tcl_Obj **objv)
{
	Tcl_Obj     *result = Tcl_GetObjResult(ip);
	int	     n = 1;
	ARecType *type;

    if ( objc != 2 ) {
	Tcl_SetStringObj(result, "TypeCreate type", -1);				\
	return TCL_ERROR;
    }

    ARecTypeCreate(ip, objv[1]);

    Tcl_SetObjResult(ip, objv[1]);	

    return TCL_OK;
}

int ARecInstObjCmd(data, ip, objc, objv)
    ClientData       data;
    Tcl_Interp      *ip;
    int              objc;
    Tcl_Obj        **objv;
{
    Tcl_Obj *result = Tcl_GetObjResult(ip);

    ARecField *inst = (ARecField *) data;
    char        *recs;

    int n, m, islist = 0;

    ARecCmd(ip, inst, "length", " ", objc == 2 || objc == 3, objc, objv,
	int n;

	if ( objc == 3 ) {
	    if ( Tcl_GetIntFromObj(ip, objv[2], &n) != TCL_OK  ) { return TCL_ERROR; }

	    ARecRealloc(inst, n, 0);
	    inst->nrecs = n;
	}

	Tcl_SetIntObj(result, inst->nrecs);

	return TCL_OK;
    );

    if ( ARecRange(ip, inst, &objc, &objv, &n, &m, &islist) == TCL_ERROR ) {		// All commands below here allow ranges.
	return TCL_ERROR;
    }

    if ( n == 0 && m == 0 ) { m = inst->nrecs;  islist = 1; }

    if ( n < 0 || n+m-1 > inst->nrecs )  {
	char index[50];
	sprintf(index, "%d %d : %d", n, m, inst->nrecs);

	Tcl_AppendStringsToObj(result, Tcl_GetString(inst->nameobj), " : index out of range ", index, NULL);

	return TCL_ERROR;
    }

    ARecCmd(ip, inst, "set", " field value ...", objc >= 3, objc, objv,
	ARecRealloc(inst, n+m, 10);

	recs = inst->recs + n * inst->type->size;

	return ARecSetFromArgs(ip, inst->type, recs, m, objc-2, objv+2, islist);
    );

    ARecCmd(ip, inst, "setdict", " field value ...", objc >= 3, objc, objv,
	ARecRealloc(inst, n+m, 10);

	recs = inst->recs + n * inst->type->size;

	return ARecSetFromDict(ip, inst->type, recs, m, objc-2, objv+2, islist);
    );
    ARecCmd(ip, inst, "setlist", " field value ...", objc >= 3, objc, objv,
	ARecRealloc(inst, n+m, 10);

	recs = inst->recs + n * inst->type->size;

	return ARecSetFromList(ip, inst->type, recs, m, objc-2, objv+2, islist);
    );

    if ( n + m-1 >= inst->nrecs ) {						// All commands below here do not allow extension
	char index[50];
	sprintf(index, "%d %d", n, m);

	Tcl_AppendStringsToObj(result , Tcl_GetString(inst->type->nameobj), " index out of range ", index, NULL);
	
	return TCL_ERROR;
    }

    recs = inst->recs + n * inst->type->size;

    ARecCmd(ip, inst, "get"    , " ?field? ...", objc >= 2, objc, objv,
	Tcl_Obj *reply = ARecGetStruct(ip, inst->type, recs, m, objc-2, objv+2, (islist ? AREC_ISLIST : 0));
	if ( !reply ) {
	    return TCL_ERROR;
	} else {
	    Tcl_SetObjResult(ip, reply);
	    return TCL_OK;
	}
    );
    ARecCmd(ip, inst, "getlist", " ?field? ...", objc >= 2, objc, objv,
	Tcl_Obj *reply = ARecGetStruct(ip, inst->type, recs, m, objc-2, objv+2, (islist ? AREC_ISLIST : 0));
	if ( !reply ) {
	    return TCL_ERROR;
	} else {
	    Tcl_SetObjResult(ip, reply);
	    return TCL_OK;
	}
    );
    ARecCmd(ip, inst, "getdict", " ?field? ...", objc >= 2, objc, objv,
	Tcl_Obj *reply = ARecGetStruct(ip, inst->type, recs, m, objc-2, objv+2, (islist ? AREC_ISLIST : 0) | AREC_ASDICT);
	if ( !reply ) {
	    return TCL_ERROR;
	} else {
	    Tcl_SetObjResult(ip, reply);
	    return TCL_OK;
	}
    );

    ARecCmd(ip, inst, "getbytes", " ", objc == 2, objc, objv,
	Tcl_SetByteArrayObj(result, inst->recs, inst->nrecs * inst->type->size);
	return TCL_OK;
    );
    ARecCmd(ip, inst, "getptr", " ", objc == 2, objc, objv,
	Tcl_SetLongObj(result, (long) recs);
	return TCL_OK;
    );
    ARecCmd(ip, inst, "setbytes", " ", objc == 3, objc, objv,
	int nbytes;
	unsigned char *bytes = Tcl_GetByteArrayFromObj(objv[2], &nbytes);
	memcpy(inst->recs, bytes, nbytes);
	return TCL_OK;
    );

    {
	ARecField *field;

	ARecCmd(ip, inst, ".", " ", 1, objc, objv, objv++;  objc--; );

	if ( (field = ARecLookupField(inst->type->nfield, inst->type->field, objv[1])) ) {
	    objv++;  objc--;

	    field->recs = (char *) recs + field->offset;

	    return ARecInstObjCmd(field, ip, objc, objv);
	}
    }

    ARecUnknownMethod(ip, inst, objc, objv);

    return TCL_ERROR;
}

ARecField *ARecInstCreate(Tcl_Interp *ip, Tcl_Obj *nameobj, ARecType *type, int n)
{
	ARecField *inst;

    inst          = (ARecField *) Tcl_Alloc(sizeof(ARecField));
    inst->nameobj = nameobj;
    Tcl_IncrRefCount(inst->nameobj);

    inst->type    = type;
    inst->nrecs   = n;
    inst->arecs   = n;
    inst->recs    = Tcl_Alloc(type->size * inst->nrecs);

    memset(inst->recs, 0, type->size * inst->nrecs);

    Tcl_CreateObjCommand(ip, Tcl_GetString(nameobj)
	, ARecInstObjCmd
	, (ClientData) inst
	, (Tcl_CmdDeleteProc *) ARecDelInst);

    Tcl_SetObjResult(ip, nameobj);

    //inst->next = type->instances;
    type->instances = inst;

    return inst;
}

int ARecNewInst(Tcl_Interp *ip, int objc, Tcl_Obj **objv, ARecType *type)
{
	Tcl_Obj     *result = Tcl_GetObjResult(ip);
	int	     n = 1;

    if ( objc == 4 ) {
	if ( Tcl_GetIntFromObj(ip, objv[3], &n) != TCL_OK  ) {
	    Tcl_SetStringObj(result, "cannot convert size arg to int", -1);				\
	    return TCL_ERROR;
	}
    }

    ARecInstCreate(ip, objv[2], type, n);

    return TCL_OK;
}

int ARecTypeFields(Tcl_Interp *ip, ARecType *type, int types, int fields, int offset)
{
    Tcl_Obj  	 *result = Tcl_NewObj();
    int i;

    for ( i = 0; i < type->nfield; i++ ) {
	if ( types  ) { Tcl_ListObjAppendElement(ip, result , type->field[i].type->nameobj); 	     }
	if ( fields ) { Tcl_ListObjAppendElement(ip, result,  type->field[i].nameobj);       	     }
	if ( offset ) { Tcl_ListObjAppendElement(ip, result,  Tcl_NewIntObj(type->field[i].offset)); }
    }

    Tcl_SetObjResult(ip, result);

    return TCL_OK;
}

void ARecTypeAddField1(ARecType *type, Tcl_Obj *nameobj, int length, ARecType *field) {
    int  i;
    int size = 0;
    int maxx;

    if ( type->nfield >= type->afield-1 ) {
	type->afield += 10;
	type->field = (ARecField *) Tcl_Realloc((char *) type->field, sizeof(ARecField) * type->afield);
    }

    maxx = type->align;

    for ( i = 0; i < type->nfield; i++ ) {
	size = ARecPadd(size + type->field[i].type->size, type->field[i].type->align);

	if ( type->field[i].type->align > maxx ) {
	    maxx = type->field[i].type->align;
	}
    }

    type->field[type->nfield].nameobj = nameobj;
    Tcl_IncrRefCount(nameobj);

    type->field[type->nfield].offset = ARecPadd(size, field->align);
    type->field[type->nfield].type   = field;
    type->field[type->nfield].nrecs  = length;
    type->field[type->nfield].arecs  = length;

    size	= ARecPadd(size + field->size*length, field->align);
    type->size	= ARecPadd(size, maxx);

    type->nfield++;
    if ( type != type->shadow ) { memcpy(type->shadow, type, sizeof(ARecType)); }
}

int ARecTypeAddField(Tcl_Interp *ip, ARecType *type, int objc, Tcl_Obj **objv)
{
    Tcl_Obj  	 *result = Tcl_GetObjResult(ip);
    int i;

    ARecType *field;

    if ( type->instances ) {
	Tcl_AppendStringsToObj(result, Tcl_GetString(objv[0]), " already has instances", NULL); 
	return TCL_ERROR;
    }

    if ( !(field = ARecLookupType(objv[2])) ) {
	Tcl_AppendStringsToObj(result, Tcl_GetString(objv[2]), " unknown data type ", NULL); 
	return TCL_ERROR;
    }

    for ( i = 3; i < objc; i++ ) {
	Tcl_Obj *name   = objv[i];
	long	 length = 1;

	if ( ARecLookupField(type->nfield, type->field, objv[i]) ) {
	    Tcl_AppendStringsToObj(result, Tcl_GetString(objv[0]), " already has a field named ", Tcl_GetString(objv[i]), NULL);
	    return TCL_ERROR;
	}

	if ( i < objc-1 && isdigit(*Tcl_GetString(objv[i+1])) ) {
	    i++;

	    if ( Tcl_GetLongFromObj(NULL, objv[i], &length) != TCL_OK ) {
		Tcl_AppendStringsToObj(result, Tcl_GetString(objv[0]), " for field ", name, " cannot convert to length ", Tcl_GetString(objv[i]), NULL);
		return TCL_ERROR;
	    }
	}

	ARecTypeAddField1(type, name, length, field);
    }

    return TCL_OK;
}


ARecField **ARecFieldMap(Tcl_Obj *result, int objc, Tcl_Obj **objv, ARecType *type, int *nmap)
{
    int 	i;
    int		max = objc > type->nfield ? objc : type->nfield;
    ARecField **map = (ARecField **) Tcl_Alloc(sizeof(ARecField *) * max);

    if ( !objc ) {
	for ( i = 0; i < type->nfield; i++ ) {
	    map[i] = &type->field[i];
	}
    } else {
	for ( i = 0; i < objc; i++ ) {
	    if ( !(map[i] = ARecLookupField(type->nfield, type->field, objv[i])) ) {
		Tcl_Free((char *) map);

		Tcl_AppendStringsToObj(result, " in type \"", Tcl_GetString(type->nameobj), "\" cannot lookup field \"", Tcl_GetString(objv[i]), "\"", NULL);
		return NULL;
	    }
	}
    }

    if ( !i ) { 
	Tcl_Free((char *) map);

	Tcl_AppendStringsToObj(result, Tcl_GetString(type->nameobj), " no fields in this type? ", NULL);
	return NULL;
    }

    *nmap = i;
    return map;
}


int ARecIndex(ARecField *inst, Tcl_Obj *result, int *objc, Tcl_Obj ***objv, int *n, int *islist)
{
	char *here = NULL;

    Tcl_Obj *index = (*objv)[1];

    if ( Tcl_GetIntFromObj(NULL, index, n) == TCL_OK  ) {
	(*objc)--;
	(*objv)++;
	if ( islist ) { *islist = 1; }
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
	    if ( islist ) { *islist = 1; }
	}
    }

    return TCL_OK;
}

ARecRealloc(ARecField *inst, int nrecs, int more) 
{
    if ( nrecs >=  inst->arecs ) {
	inst->arecs = nrecs + more;
	inst->recs  = Tcl_Realloc((char *) inst->recs, inst->arecs * inst->type->size);

	memset(&((char *)inst->recs)[inst->nrecs * inst->type->size], 0, inst->type->size * ((nrecs - inst->nrecs) + more));
    }
    inst->nrecs = Max(nrecs, inst->nrecs);
}

int ARecRange(Tcl_Interp *ip, ARecField *inst, int *objc, Tcl_Obj ***objv, int *n, int *m, int *islist)
{
    Tcl_Obj  	 *result = Tcl_GetObjResult(ip);
    int	indx = 0;

    *n = 0;
    *m = 0;

    if ( *objc > 1 && ARecIndex(inst, result, objc, objv, n,  &indx)   != TCL_OK  ) { return TCL_ERROR; }
    *m = *n;								

    if ( !indx ) { return TCL_OK; }

    if ( *objc > 1 && ARecIndex(inst, result, objc, objv, m, islist) != TCL_OK  ) { return TCL_ERROR; }

    *m = *m - *n + 1;

    return TCL_OK;
}

int ARecSetFromArgs(Tcl_Interp *ip, ARecType *type, char *recs, int n, int objc, Tcl_Obj **objv, int islist)
{
    	int i, j;
	int list = 0;
	Tcl_Obj *result = Tcl_GetObjResult(ip);

    if ( objc % 2 ) {
	return ARecSetFromList(ip, type, recs, n, objc, objv, islist);
    }

    for ( j = 0; j < n; j++ ) {
	for ( i = 0; i < objc; i += 2 ) {
	    ARecField *field = ARecLookupField(type->nfield, type->field, objv[i+0]);

	    if ( !field ) {
		Tcl_AppendStringsToObj(result , Tcl_GetString(type->nameobj) , " field "
			, Tcl_GetString(objv[i+0]), " not defined "
			, NULL);
		return TCL_ERROR;
	    }
	    if ( ARecSetField(ip, field, recs, objv[i+1]) == TCL_ERROR ) {
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

int ARecSetFromDict(Tcl_Interp *ip, ARecType *type, char *recs, int n, int objc, Tcl_Obj **objv, int islist)
{
    	int i, j;
	Tcl_Obj *result = Tcl_GetObjResult(ip);

	int	  elemc;
	Tcl_Obj	**elemv;

    if ( Tcl_ListObjGetElements(ip, objv[0], &objc, &objv) == TCL_ERROR ) {
	return TCL_ERROR;
    }

    for ( j = 0; j < n; j++ ) {
	if ( Tcl_ListObjGetElements(ip, objv[j % objc], &elemc, &elemv) == TCL_ERROR ) {
	    return TCL_ERROR;
	}

        if ( elemc % 2 ) {
	    Tcl_AppendStringsToObj(result
		    , Tcl_GetString(type->nameobj) , " cannot set fields from an odd number of elements"
		    , NULL);
	    return TCL_ERROR;
	}

	for ( i = 0; i < elemc; i += 2 ) {
	    if ( ARecSetField(ip, ARecLookupField(type->nfield, type->field, elemv[i+0]), recs, elemv[i+1]) == TCL_ERROR ) {
		Tcl_AppendStringsToObj(result, Tcl_GetString(type->nameobj), " cannot set field ", Tcl_GetString(elemv[i+0]), " from ", Tcl_GetString(elemv[i+1]), NULL);
		return TCL_ERROR;
	    }
	}

	recs += type->size;
    }

    return TCL_OK;
}

int ARecSetFromList(Tcl_Interp *ip, ARecType *type, char *inst, int n, int objc, Tcl_Obj **objv, int islist)
{
	ARecField *table = type->field;
	Tcl_Obj  	 *result = Tcl_GetObjResult(ip);

        ARecField **map;
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

    if ( Tcl_ListObjGetElements(ip, objv[objc - 1], &objc, &objv) == TCL_ERROR ) {
	Tcl_Free((void *) map);
	return TCL_ERROR;
    }

    for ( j = 0; j < n; j++ ) {
	if ( Tcl_ListObjGetElements(ip, objv[j % objc], &elemc, &elemv) == TCL_ERROR ) {
	    Tcl_Free((void *) map);
	    return TCL_ERROR;
	}

	for ( i = 0, m = 0; i < elemc && m < nmap; i++, m++ ) {
	    if ( ARecSetField(ip, map[m], inst, elemv[i]) == TCL_ERROR ) {
		Tcl_AppendStringsToObj(result, Tcl_GetString(type->nameobj), " cannot set field ", Tcl_GetString(map[m]->nameobj), " of type ", Tcl_GetString(map[m]->type->nameobj), " from ", Tcl_GetString(elemv[i]), NULL);
		Tcl_Free((void *) map);
		return TCL_ERROR;
	    }
	}

	inst += type->size;
    }

    Tcl_Free((void *) map);
    return TCL_OK;
}

Tcl_Obj *ARecGetStruct(Tcl_Interp *ip, ARecType *type, void *recs, int m, int objc, Tcl_Obj **objv, int flags)
{
    	int i, j;

	Tcl_Obj    *result = Tcl_NewObj();
        ARecField **map;
	int	   nmap;

    if ( !(map = ARecFieldMap(result, objc, objv, type, &nmap)) ) {
	return NULL;
    }

    for ( j = 0; j < m; j++ ) {
	    Tcl_Obj *reply = Tcl_NewObj();

	for ( i = 0 ; i < nmap; i++ ) {

	    Tcl_Obj *value = map[i]->type->get(ip, map[i]->type, ((char *)recs) + map[i]->offset, map[i]->nrecs, 0, NULL, (map[i]->nrecs > 1 ? AREC_ISLIST : 0));

	    if ( value == NULL ) {
		Tcl_Free((void *) map);
		return NULL;
	    }

	    if ( nmap > 1 || flags & AREC_ISLIST || flags & AREC_ASDICT ) {
		if ( flags & AREC_ASDICT ) {
		    if ( Tcl_ListObjAppendElement(ip, reply, map[i]->nameobj) == TCL_ERROR ) {
			Tcl_Free((void *) map);
			return NULL;
		    }
		}

		if ( Tcl_ListObjAppendElement(ip, reply, value) == TCL_ERROR ) {
		    Tcl_Free((void *) map);
		    return NULL;
		}
	    } else {
		result = value;
	    }
	}
	if ( flags & AREC_ISLIST || flags & AREC_ASDICT ) {
	    if ( Tcl_ListObjAppendElement(ip, result, reply) == TCL_ERROR ) {
		Tcl_Free((void *) map);
		return NULL;
	    }
	} else {
	    if ( nmap > 1 ) { result = reply; }
	}

	recs = (void *) ((char *)recs) + type->size;
    }

    Tcl_Free((void *) map);

    return result;
}

typedef struct _LngAlign { long	  x; char y; } LngAlign;
typedef struct _DblAlign { double x; char y; } DblAlign;

ARecType *ARecTypeAddType(ARecField *types, Tcl_Obj *nameobj, int size, int align, ARecSetFunc set, ARecGetFunc get)
{
    ARecType *type;

    if ( types ) {
	ARecRealloc(types, ++types->nrecs, 10);

	type = &((ARecType *)(types->recs))[types->nrecs-1];
	type->shadow = (ARecType *) Tcl_Alloc(sizeof(ARecType));
    } else {
	type = (ARecType *) Tcl_Alloc(sizeof(ARecType));
	type->shadow = type;
    }

    type->nameobj = nameobj;
    Tcl_IncrRefCount(type->nameobj);

    type->size   =  size;
    type->align  =  align;
    type->nfield =  0;
    type->afield = 10;
    type->field  = (ARecField *) Tcl_Alloc(sizeof(ARecField) * type->afield);
    type->instances = NULL;

    type->set = set;
    type->get = get;

    type->field[0].nameobj = NULL;

    if ( types ) {
	memcpy(type->shadow, type, sizeof(ARecType));
    }

    return type;
}

void ARecInit(Tcl_Interp *ip) {
    ARecType *type;
    int i;

    Tcl_Obj *tclobjString = Tcl_NewStringObj("string", -1);
    Tcl_Obj *tclobjLong   = Tcl_NewStringObj("long", -1);
    Tcl_Obj *tclobjTclObj = Tcl_NewStringObj("tclobj*",-1);

    int dalign = sizeof(DblAlign) - sizeof(double);
    int lalign = sizeof(LngAlign) - sizeof(long);

    ARecTypeType = ARecTypeCreate(ip, Tcl_NewStringObj("::arec::type", -1));
    ARecTypeType->size = sizeof(ARecType);


    ARecTypeInst = ARecInstCreate(ip, Tcl_NewStringObj("::arec::types", -1), ARecTypeType, 0);

    ARecTypeAddType(ARecTypeInst, Tcl_NewStringObj("char",   -1), sizeof(char)	  	, 1,      ARecSetChar,	ARecGetChar   );
    ARecTypeAddType(ARecTypeInst, Tcl_NewStringObj("uchar",  -1), sizeof(unsigned char) , 1,      ARecSetUChar,	ARecGetUChar  );
    ARecTypeAddType(ARecTypeInst, Tcl_NewStringObj("short",  -1), sizeof(short)	  	, 2,      ARecSetShort,	ARecGetShort  );
    ARecTypeAddType(ARecTypeInst, Tcl_NewStringObj("ushort", -1), sizeof(unsigned short), 2,      ARecSetUShort, 	ARecGetUShort );
    ARecTypeAddType(ARecTypeInst, Tcl_NewStringObj("int",    -1), sizeof(int)		, 4,      ARecSetInt,	ARecGetInt    );
    ARecTypeAddType(ARecTypeInst, tclobjLong,	                  sizeof(long)	  	, lalign, ARecSetLong,	ARecGetLong   );
    ARecTypeAddType(ARecTypeInst, Tcl_NewStringObj("float",  -1), sizeof(float)	  	, 4,      ARecSetFloat,	ARecGetFloat  );
    ARecTypeAddType(ARecTypeInst, Tcl_NewStringObj("double", -1), sizeof(double)	, dalign, ARecSetDouble, 	ARecGetDouble );
    ARecTypeAddType(ARecTypeInst, tclobjString,	                  sizeof(char *)	, 4,      ARecSetString, 	ARecGetString );
    ARecTypeAddType(ARecTypeInst, tclobjTclObj,		          sizeof(Tcl_Obj *)	, 4,      NULL         , 	ARecGetTclObj );

    ARecTypeType->size = 0;

    ARecTypeAddField1(ARecTypeType, Tcl_NewStringObj("name",  -1), 1, ARecLookupType(tclobjTclObj));
    ARecTypeAddField1(ARecTypeType, Tcl_NewStringObj("size",  -1), 1, ARecLookupType(tclobjLong));
    ARecTypeAddField1(ARecTypeType, Tcl_NewStringObj("align", -1), 1, ARecLookupType(tclobjLong));
    ARecTypeAddField1(ARecTypeType, Tcl_NewStringObj("nfield",-1), 1, ARecLookupType(tclobjLong));
    ARecTypeAddField1(ARecTypeType, Tcl_NewStringObj("afield",-1), 1, ARecLookupType(tclobjLong));
    ARecTypeAddField1(ARecTypeType, Tcl_NewStringObj("fields",-1), 1, ARecLookupType(tclobjLong));
    ARecTypeAddField1(ARecTypeType, Tcl_NewStringObj("set",   -1), 1, ARecLookupType(tclobjLong));
    ARecTypeAddField1(ARecTypeType, Tcl_NewStringObj("get",   -1), 1, ARecLookupType(tclobjLong));
    ARecTypeAddField1(ARecTypeType, Tcl_NewStringObj("shadow",-1), 1, ARecLookupType(tclobjLong));
    ARecTypeAddField1(ARecTypeType, Tcl_NewStringObj("inst",  -1), 1, ARecLookupType(tclobjLong));
}

