#ifndef EBT_UNORDERED_MAP_H
#define EBT_UNORDERED_MAP_H

#include <unordered_map>
#include "option.h"
#include "json.h"

namespace ebt {

    template <class K, class V>
    bool in(K const &key, std::unordered_map<K, V> const &map)
    {
        return map.find(key) != map.end();
    }
    
    template <class K, class V>
    Option<V> get(std::unordered_map<K, V> const &map, K const &key)
    {
        if (map.find(key) == map.end()) {
            return none<V>();
        } else {
            return some(map.at(key));
        }
    }
    
    template <class K, class V>
    V const & get(std::unordered_map<K, V> const &map, K const &key,
        V const &default_)
    {
        if (map.find(key) == map.end()) {
            return default_;
        } else {
            return map.at(key);
        }
    }

}

namespace std {

    template <class T>
    ostream& operator<<(ostream& os, unordered_map<string, T> const& map)
    {
        ebt::json::dump(map, os);
        return os;
    }

}

#endif
