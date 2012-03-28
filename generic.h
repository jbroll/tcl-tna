
typedef unsigned short ushort;
typedef unsigned int   uint;
typedef unsigned long  ulong;

#define TYPES_INT(FUNCTION)				\
    FUNCTION(char)					\
    FUNCTION(ushort)					\
    FUNCTION(short)					\
    FUNCTION(int)					\
    FUNCTION(uint)					\
    FUNCTION(long)					\
    FUNCTION(ulong)

#define TYPES_FLT(FUNCTION)				\
    FUNCTION(float)					\
    FUNCTION(double)

#define TYPES_TWO(FUNCTION)				\
    TYPES2TWO(FUNCTION, char)				\
    TYPES2TWO(FUNCTION, ushort)				\
    TYPES2TWO(FUNCTION, short)				\
    TYPES2TWO(FUNCTION, int)				\
    TYPES2TWO(FUNCTION, uint)				\
    TYPES2TWO(FUNCTION, float)				\
    TYPES2TWO(FUNCTION, double)
    
#define TYPES2TWO(FUNCTION, type)			\
    FUNCTION(type, char)				\
    FUNCTION(type, ushort)				\
    FUNCTION(type, short)				\
    FUNCTION(type, int)					\
    FUNCTION(type, uint)				\
    FUNCTION(type, float)				\
    FUNCTION(type, double)
