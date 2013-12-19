#include "hash.h"

namespace ebt {

    size_t & hash_combine(size_t &seed, size_t value)
    {
        seed ^= value + 0x9e3779b9
            + (seed >> 6) + (seed << 2);
        return seed;
    }

}

