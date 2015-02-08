#include "ebt/range.h"
#include <vector>
#include <string>

void test_is_range()
{
    static_assert(ebt::is_range<ebt::range<std::vector<int>>>::value, "");
    static_assert(ebt::is_range<ebt::range<std::vector<std::string>>>::value, "");
}

int main()
{
    test_is_range();

    return 0;
}
