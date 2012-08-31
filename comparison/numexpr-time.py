#!/bin/env python2.7
#

import numpy as np
import numexpr as ne

nx = 2048

a = np.ones([nx, nx], dtype=np.double) + 1
b = np.ones([nx, nx], dtype=np.double) + 4

for i in range(100):
    c = ne.evaluate("a*a + b*b + 2*a*b")

print c[0][0]

