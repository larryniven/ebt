#ifndef EBT_UNORDERED_SET_H
#define EBT_UNORDERED_SET_H

#include <unordered_set>

namespace ebt {

    template <class T>
    bool in(T const &t, std::unordered_set<T> const &set)
    {
        return set.find(t) != set.end();
    }

}

#endif
