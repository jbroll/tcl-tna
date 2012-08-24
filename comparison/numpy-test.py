
import numpy as np

nx = 2048

a = np.ones([nx, nx], dtype=np.double) + 1
b = np.ones([nx, nx], dtype=np.double) + 4

for i in range(100):
    c = a*a + b*b + 2 * a * b

