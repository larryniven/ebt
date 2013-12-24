#ifndef EBT_EXCEPTION_H
#define EBT_EXCEPTION_H

#include <string>

namespace ebt {

    class parser_exception : public std::exception {
    public:
        parser_exception(std::string msg);

        char const* what() const noexcept;

    private:
        std::string msg_;
    };

}

#endif
