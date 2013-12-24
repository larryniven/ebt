#ifndef EBT_STRING_H
#define EBT_STRING_H

#include "range.h"
#include <string>
#include <ostream>
#include <sstream>
#include <vector>

namespace ebt {

    template <class range>
    typename std::enable_if<is_range<range>::value, std::ostream&>::type
    join(range r, std::string sep, std::ostream& os)
    {
        while (!r.empty()) {
            os << r.front();
            r.pop_front();

            if (!r.empty()) {
                os << sep;
            }
        }

        return os;
    }

    template <class container>
    typename std::enable_if<!is_range<container>::value, std::ostream&>::type
    join(container const& con, std::string sep, std::ostream& os)
    {
        return join(make_range(con), sep, os);
    }

    template <class container>
    std::string join(container const& con, std::string sep)
    {
        std::ostringstream oss;
        join(con, sep, oss);
        return oss.str();
    }

    std::ostream& format(std::ostream& os, std::string fmt);

    template <typename T, typename... Args>
    std::ostream& format(std::ostream& os, std::string fmt,
        T const& t, Args const&... args)
    {
        unsigned int i;
    
        for (i = 0; i < fmt.size(); ++i) {
            if (fmt.at(i) == '{') {
                if (fmt.at(i + 1) == '{') {
                    ++i;
                    os << '{';
                } else if (fmt.at(i + 1) == '}') {
                    i += 2;
                    os << t;
                    break;
                }
            } else if (fmt.at(i) == '}' && fmt.at(i + 1) == '}') {
                ++i;
                os << '}';
            } else {
                os << fmt.at(i);
            }
        }
    
        return format(os, fmt.substr(i), args...);
    }
    
    template <typename... Args>
    std::string format(std::string fmt, Args const&... args)
    {
        std::ostringstream oss;
        format(oss, std::move(fmt), args...);
        return oss.str();
    }

    std::vector<std::string> split(std::string const& s,
        std::string sep="");

    std::string replace(std::string s, std::string pattern,
        std::string replacement);
    
    std::string strip(std::string const& str, std::string const& chars=" \t\n");

    std::string escapeseq(std::string const& s);

    std::string upper(std::string const& s);

    std::string lower(std::string const& s);

    bool startswith(std::string const& s, std::string const& prefix);

    bool endswith(std::string const& s, std::string const& suffix);

    std::vector<std::string> split_utf8_chars(std::string const &s);

}

#endif
