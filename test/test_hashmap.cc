#include "ebt/hashmap.h"
#include <iostream>

void test_simple()
{
    ebt::hashmap<std::string, std::string> map;

    for (int i = 0; i < 10; ++i) {
        map[std::to_string(i)] = std::to_string(i);
    }
}

void test_insert_and_search()
{
    ebt::hashmap<std::string, std::string> map;

    for (int i = 0; i < 1000000; ++i) {
        map[std::to_string(i)] = std::to_string(i);
    }

    std::string k;

    for (int i = 0; i < 1000000; ++i) {
        try {
            if (map.at(std::to_string(i)) != std::to_string(i)) {
                std::cout << "search failed" << std::endl;
                exit(1);
            }
        } catch (std::exception const& e) {
            k = std::to_string(i);
        }
    }

    std::cout << map.max_probe_count_ << " " << map.min_probe_count_ << std::endl;

    for (int i = 0; i < map.probe_count_dist_.size(); ++i) {
        std::cout << i << ": " << map.probe_count_dist_.at(i) << std::endl;
    }

    std::cout << std::endl;

    if (k.size() == 0) {
        return;
    }

    std::cout << "key: " << k << std::endl;

    int base = map.hash_func_(k) % map.buckets_.size();

    for (int i = base; i < base + 10; ++i) {
        std::cout << i << ": ";
        map.print(std::cout, map.buckets_.at(i));
        std::cout << " " << map.probe_count_at(i);
        std::cout << std::endl;
    }

    for (int i = 0; i < 1000000; ++i) {
        if (map.in("foo " + std::to_string(i))) {
            std::cout << "foo " + std::to_string(i) << " should not be in the map" << std::endl;
            break;
        }
    }
}

int main()
{
    test_simple();
    test_insert_and_search();

    return 0;
}
