#include "math.h"
#include <cmath>
#include <algorithm>

namespace ebt {

    double log_add(double a, double b)
    {
        return std::max(a, b)
            + std::log(1 + std::exp(std::min(a, b) - std::max(a, b)));
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
