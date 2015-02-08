#ifndef EBT_TUPLE_H
#define EBT_TUPLE_H

#include <tuple>
#include "ebt/hash.h"
#include "ebt/json.h"

namespace std {

    template <size_t i, class... Args>
    struct hash_tuple {
        size_t& operator()(size_t &seed, tuple<Args...> const &t) const
        {
            hash_tuple<i-1, Args...> init;
            hash<typename tuple_element<i, tuple<Args...>>::type> hasher;
            return ebt::hash_combine(init(seed, t), hasher(get<i>(t)));
        }
    };
    
    template <class... Args>
    struct hash_tuple<0, Args...> {
        size_t & operator()(size_t &seed, tuple<Args...> const &t) const
        {
            hash<typename tuple_element<0, tuple<Args...>>::type> hasher;
            return ebt::hash_combine(seed, hasher(get<0>(t)));
        }
    };
    
    template <class... Args>
    struct hash<tuple<Args...>> {
        size_t operator()(tuple<Args...> const &t) const noexcept
        {
            size_t seed = 0;
            return hash_tuple<tuple_size<tuple<Args...>>::value - 1,
                Args...>()(seed, t);
        }
    };

    template <class... Args>
    std::ostream& operator<<(std::ostream& os, std::tuple<Args...> const& t)
    {
        ebt::json::dump(t, os);
        return os;
    }
}

#endif
