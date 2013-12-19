#ifndef EBT_HASH_H
#define EBT_HASH_H

#include <cstddef>

namespace ebt {

    size_t & hash_combine(size_t &seed, size_t value);

}

#endif
