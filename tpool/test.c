
#include <stdlib.h>

#include "/home/john/pkg/tcl/generic/tcl.h"
#include "tpool.h"


TPoolWork *work(void *data) {
    printf("Here %d\n", data);
    sleep(data);
    printf("Thread %d\n", data);
}



int main() {

    TPool *tp = TPoolInit(5);

    TPoolStart(tp, work, 1);
    TPoolStart(tp, work, 2);
    TPoolStart(tp, work, 3);
    TPoolStart(tp, work, 4);
    TPoolStart(tp, work, 5);
    TPoolStart(tp, work, 6);
    TPoolStart(tp, work, 7);

    sleep(10);


    return 0;
}
