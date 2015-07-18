#include "ebt/assert.h"
#include "ebt/functional.h"
#include <vector>

void test_map()
{
    std::vector<std::string> vec = {"a", "aa", "aaa"};
    auto r = ebt::map(vec, [](std::string const& s) { return s.size(); });
    ebt::assert_equals(1, r.front());
    r.pop_front();
    ebt::assert_equals(2, r.front());
    r.pop_front();
    ebt::assert_equals(3, r.front());
}

void test_map_iterator()
{
    std::vector<std::string> vec = {"a", "aa", "aaa"};
    auto r = ebt::map(vec, [](std::string const& s) { return s.size(); });
    std::vector<int> exp = {1, 2, 3};
    auto exp_r = ebt::make_range(exp);

    for (auto &e: r) {
        ebt::assert_equals(exp_r.front(), e);
        exp_r.pop_front();
    }
}

int main()
{
    test_map();
    test_map_iterator();

    return 0;
}
