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

    template <class A, class B, class C>
    struct hash<tuple<A, B, C>> {
        size_t operator()(tuple<A, B, C> const& t) const noexcept
        {
            hash<A> a_hasher;
            hash<B> b_hasher;
            hash<C> c_hasher;

            size_t result = a_hasher(std::get<0>(t));
            ebt::hash_combine(result, b_hasher(std::get<1>(t)));
            return ebt::hash_combine(result, c_hasher(std::get<2>(t)));
        }
    };

    template <class A, class B>
    struct hash<tuple<A, B>> {
        size_t operator()(tuple<A, B> const& t) const noexcept
        {
            hash<A> a_hasher;
            hash<B> b_hasher;

            size_t result = a_hasher(std::get<0>(t));
            return ebt::hash_combine(result, b_hasher(std::get<1>(t)));
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
