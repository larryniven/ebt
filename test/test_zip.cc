#include "ebt/assert.h"
#include "ebt/functional.h"
#include <vector>
#include <string>

void test_zip()
{
    std::vector<int> a {1, 2, 3};
    std::vector<std::string> b {"a", "aa", "aaa"};

    auto r = ebt::zip(a, b);

    ebt::assert_equals(1, std::get<0>(r.front()));
    ebt::assert_equals(std::string("a"), std::get<1>(r.front()));
    r.pop_front();
    ebt::assert_equals(2, std::get<0>(r.front()));
    ebt::assert_equals(std::string("aa"), std::get<1>(r.front()));
    r.pop_front();
    ebt::assert_equals(3, std::get<0>(r.front()));
    ebt::assert_equals(std::string("aaa"), std::get<1>(r.front()));
    r.pop_front();
    ebt::assert(r.empty(), "r should be empty");
}

int main()
{
    test_zip();

    return 0;
}
