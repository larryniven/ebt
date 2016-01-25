#include "math_util.h"
#include <cmath>
#include <algorithm>

namespace ebt {

    double log_add(double a, double b)
    {
        if (a > b) {
            return a + std::log(1 + std::exp(b - a));
        } else {
            return b + std::log(1 + std::exp(a - b));
        }
    }

    double sign(double x)
    {
        if (x == 0) {
            return 0;
        } else if (x > 0) {
            return 1;
        } else {
            return -1;
        }
    }

}
