#include "ebt/assert.h"

namespace ebt {

    void assert(bool condition, std::string msg)
    {
        if (!condition) {
            std::cerr << msg << std::endl;
            exit(1);
        }
    }

}
