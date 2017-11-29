#ifndef EBT_UNIT_TEST_H
#define EBT_UNIT_TEST_H

#include <string>
#include <iostream>
#include <cmath>
#include <sstream>
#include <exception>

namespace ebt {

    template <class T, class U = T>
    typename std::enable_if<!std::is_floating_point<T>::value, void>::type
    assert_equals(T const &expected, U const &actual)
    {
        if (expected != actual) {
            std::ostringstream oss;
            oss << "expected: <" << expected << "> but was: <"
                << actual << ">" << std::endl;
            throw std::logic_error(oss.str());
        }
    }
    
    template <class T, class U = T>
    typename std::enable_if<std::is_floating_point<T>::value, void>::type
    assert_equals(T expected, U actual)
    {
        if (std::fabs(expected - actual) > std::fabs(expected) * 1e-6) {
            std::ostringstream oss;
            oss << "expected: <" << expected << "> but was: <"
                << actual << ">" << std::endl;
            throw std::logic_error(oss.str());
        }
    }

    template <class T, class U = T>
    void assert_equals(T expected, U actual, double eps)
    {
        if (std::fabs(expected - actual) > eps) {
            std::ostringstream oss;
            oss << "expected: <" << expected << "> but was: <"
                << actual << ">" << std::endl;
            throw std::logic_error(oss.str());
        }
    }

}

#endif
