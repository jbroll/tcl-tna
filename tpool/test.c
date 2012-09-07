
#include <stdlib.h>

#include "/Users/john/src/tcl8.5.9/generic/tcl.h"
#include "tpool.h"


TPoolWork *work(void *data) {
    printf("Here %p\n", data);
    sleep(data);
    printf("Thread %p\n", data);
}



int main() {

    TPool *tp = TPoolInit(5);

    TPoolThreadStart(tp, work, 1);
    TPoolThreadStart(tp, work, 2);
    TPoolThreadStart(tp, work, 3);
    TPoolThreadStart(tp, work, 4);
    TPoolThreadStart(tp, work, 5);
    TPoolThreadStart(tp, work, 6);
    TPoolThreadStart(tp, work, 7);

    sleep(10);


    return 0;
}
