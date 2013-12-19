#ifndef EBT_VECTOR_H
#define EBT_VECTOR_H

#include "json.h"
#include "hash.h"

namespace std {

    template <class T>
    std::ostream& operator<<(std::ostream& os, std::vector<T> const& vec)
    {
        ebt::json::dump(vec, os);
        return os;
    }

    template <class T>
    struct hash<vector<T>> {
        size_t operator()(vector<T> const &v) const noexcept
        {
            size_t result = 0;
            hash<T> e_hasher;
            for (auto &e: v) {
                ebt::hash_combine(result, e_hasher(e));
            }
            return result;
        }
    };

}

#endif
