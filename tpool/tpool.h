

typedef void (*TPoolWork)(void *data);

typedef struct _TPoolThread {
    struct _TPool *tp;
    Tcl_ThreadId   id;
    TPoolWork    func;

    Tcl_Mutex     lock;
    Tcl_Condition wait;

    void	*data;
    int		 work;
} TPoolThread;

typedef struct _TPool {
    Tcl_Mutex     lock;
    Tcl_Condition wait;

    int		next;
    int         nthread;
    TPoolThread *thread;
} TPool;

TPool *TPoolInit(int n);
TPoolThread *TPoolThreadStart(TPool *tp, TPoolWork func, void *data);
TPoolThread *TPoolThreadWair (TPoolThread *t);
