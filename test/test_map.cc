#include "unit_test.h"
#include "functional.h"
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

int main()
{
    test_map();
    return 0;
}
