#ifndef EBT_PAIR_H
#define EBT_PAIR_H

#include <utility>
#include "ebt/hash.h"

namespace std {

    template <class U, class V>
    struct hash<pair<U, V>> {
        size_t operator()(std::pair<U, V> const &p) const noexcept
        {
            hash<U> v_hasher;
            hash<V> u_hasher;
            size_t seed = 0;
            ebt::hash_combine(seed, v_hasher(p.first));
            ebt::hash_combine(seed, u_hasher(p.second));
            return seed;
        }
    };

}

#endif
