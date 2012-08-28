

#include <Eigen/Dense>
#include <iostream>

using namespace Eigen;
using namespace std;

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define NX 2048

main() {
    	int i, x, y;
	ArrayXXd a(2048,2048);
	ArrayXXd b(2048,2048);
	ArrayXXd data(2048,2048);

    for ( i = 0; i < 100; i++ ) {


	data = a*a + b*b + 2 * a*b;
    }
}
