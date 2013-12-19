#include "string.h"

namespace ebt {

    std::ostream& format(std::ostream& os, std::string fmt)
    {
        return os << fmt;
    }

    class split_impl {
    public:
        split_impl(std::string const& str, std::string const& sep="");
        std::vector<std::string> compute();
    private:
        void push_back(std::vector<std::string> &list,
            std::string const& p);
    
        std::string str_;
        std::string sep_;
    };
    
    split_impl::split_impl(std::string const& str, std::string const& sep):
        str_(str), sep_(sep)
    {
    }
    
    std::vector<std::string> split_impl::compute()
    {
        std::vector<std::string> out;
        int p = 0;
        while (1) {
            auto q = std::string::npos;
            if (sep_ != "") {
                q = str_.find(sep_, p);
            } else {
                q = str_.find_first_of(" \n\t", p);
            }
            if (q == std::string::npos) {
                push_back(out, str_.substr(p));
                break;
            }
            push_back(out, str_.substr(p, q - p));
            if (q + std::max<unsigned int>(sep_.length(), 1) <
                    str_.length()) {
                p = q + std::max<unsigned int>(sep_.length(), 1);
            } else {
                push_back(out, "");
                break;
            }
        }
    
        return out;
    }
    
    void split_impl::push_back(std::vector<std::string>& list,
        std::string const& s)
    {
        if (sep_ != "" || s != "") {
            list.push_back(s);
        }
    }
    
    std::vector<std::string> split(std::string const& s,
        std::string sep)
    {
        return split_impl(s, sep).compute();
    }

    std::string replace(std::string s, std::string pattern,
        std::string replacement)
    {
        std::vector<std::string> parts = ebt::split(s, pattern);
        return ebt::join(parts, replacement);
    }

    std::string strip(std::string const& str, std::string const& chars)
    {
        int s = 0;
        for (int i = 0; i < int(str.size()); ++i) {
            if (chars.find(str[i]) == std::string::npos) {
                break;
            }
            ++s;
        }
    
        int b = str.size();
        for (int i = int(str.size()) - 1; i >= 0; --i) {
            if (chars.find(str[i]) == std::string::npos) {
                break;
            }
            --b;
        }
    
        return str.substr(s, b - s);
    }

    std::string escapeseq(std::string const& s)
    {
        std::string result;
    
        for (auto c: s) {
            if (c == '\\') {
                result += '\\';
                result += '\\';
            } else if (c == '"') {
                result += '\\';
                result += '\"';
            } else {
                result += c;
            }
        }
    
        return result;
    }

    std::string upper(std::string const& s)
    {
        std::string result;
        for (auto& c: s) {
            result += std::toupper(c);
        }
        return result;
    }

    std::string lower(std::string const& s)
    {
        std::string result;
        for (auto& c: s) {
            result += std::tolower(c);
        }
        return result;
    }

    bool startswith(std::string const& s, std::string const& prefix)
    {
        return s.find(prefix) == 0;
    }

    bool endswith(std::string const& s, std::string const& suffix)
    {
        return s.find(suffix) == s.size() - suffix.size();
    }

    std::vector<std::string> split_utf8_chars(std::string const &s)
    {
        std::vector<std::string> result;
        std::string tmp;
        for (auto &c: s) {
            if ((c & 0xC0) == 0xC0 && !tmp.empty()) {
                result.push_back(tmp);
                tmp.clear();
            }
            tmp += c;
        }
        if (!tmp.empty()) {
            result.push_back(tmp);
        }
        return result;
    }

}
