#include "exception.h"

namespace ebt {

    parser_exception::parser_exception(std::string msg)
        : msg_(msg)
    {}

    char const* parser_exception::what() const noexcept
    {
        return msg_.c_str();
    }

}
