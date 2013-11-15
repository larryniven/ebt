% English Breakfast Tea (EBT) C++ Library
% Copyright (C) 2013  Hao Tang
% 
% EBT is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% EBT is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

\documentclass{article}
\usepackage{fullpage}

\title{ebt}
\author{Hao Tang\\\texttt{haotang@@ttic.edu}}
\date{Version 0.1}

\begin{document}

\maketitle

\tableofcontents

\section{Overview}

@<ebt.h@>=
#ifndef EBT_H
#define EBT_H

#include <vector>
#include <string>
#include <iterator>
#include <unordered_map>
#include <functional>
#include <iostream>
#include <memory>
#include <sstream>
#include <ostream>
#include <tuple>
#include <list>
#include <cctype>
#include <cmath>
#include <unordered_set>
#include <ctime>
#include <cassert>

@<assert@>

@<hash combine@>

@<uni ref@>
@<either@>
@<option@>

@<escapeseq@>
@<upper@>
@<lower@>
@<split@>
@<replace@>
@<startswith@>
@<endswith@>
@<join@>
@<format@>
@<to_string@>
@<split utf-8 chars@>

@<parser@>

@<range@>
@<zip@>
@<product@>
@<map@>
@<filter@>
@<chain@>
@<ngram@>

@<pair utility@>
@<tuple utility@>
@<vector utility@>
@<list utility@>
@<unordered_map utility@>
@<unordered_set utility@>

@<max heap@>

@<sparse vector@>

@<timer@>

@<argument parser@>

namespace std {

template <class T>
ostream & operator<<(ostream &os, std::reference_wrapper<T> const &t)
{
    os << t.get();
    return os;
}

}

#endif
@

@<ebt.cc@>=
#include "ebt.h"
#include <algorithm>

@<assert impl@>

@<escapeseq impl@>
@<upper impl@>
@<lower impl@>
@<split impl@>
@<replace impl@>
@<split utf-8 chars impl@>

@<range impl@>
@<sparse vector impl@>
@<parser impl@>

@<timer impl@>

@<argument parser impl@>

@

\section{Assert}

@<assert@>=
namespace ebt {

void assert_true(bool condition, std::string msg);

template <class T, class U = T>
typename std::enable_if<!std::is_floating_point<T>::value, void>::type
assert_equals(T const &expected, U const &actual)
{
    if (expected != actual) {
        std::cerr << "expected: <" << expected << "> but was: <"
            << actual << ">" << std::endl;
        exit(1);
    }
}

template <class T, class U = T>
typename std::enable_if<std::is_floating_point<T>::value, void>::type
assert_equals(T expected, U actual)
{
    if (std::fabs(expected - actual) > std::fabs(expected) * 1e-6) {
        std::cerr << "expected: <" << expected << "> but was: <"
            << actual << ">" << std::endl;
        exit(1);
    }
}

}
@

@<assert impl@>=
namespace ebt {

void assert_true(bool condition, std::string msg)
{
    if (!condition) {
        std::cerr << msg << std::endl;
        exit(1);
    }
}

}
@

\section{String}

@<escapeseq@>=
namespace ebt {

std::string escapeseq(std::string const &s);

}
@

@<escapeseq impl@>=
namespace ebt {

std::string escapeseq(std::string const &s)
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

}
@

@<upper@>=
namespace ebt {

std::string upper(std::string const &s);

}
@

@<upper impl@>=
namespace ebt {

std::string upper(std::string const &s)
{
    std::string result;
    for (auto &c: s) {
        result += std::toupper(c);
    }
    return result;
}

}
@

@<lower@>=
namespace ebt {

std::string lower(std::string const &s);

}
@

@<lower impl@>=
namespace ebt {

std::string lower(std::string const &s)
{
    std::string result;
    for (auto &c: s) {
        result += std::tolower(c);
    }
    return result;
}

}
@

@<startswith@>=
namespace ebt {

inline bool startswith(std::string const &s, std::string const &prefix)
{
    return s.find(prefix) == 0;
}

}
@

@<endswith@>=
namespace ebt {

inline bool endswith(std::string const &s, std::string const &suffix)
{
    return s.find(suffix) == s.size() - suffix.size();
}

}
@

@<split@>=
namespace ebt {

std::vector<std::string> split(std::string const &s,
    std::string sep="");

}
@

@<split impl@>=
namespace ebt {

class Split {
public:
    Split(std::string const &str, std::string const &sep="");
    std::vector<std::string> compute();
private:
    void push_back(std::vector<std::string> &list,
        std::string const &p);

    std::string str_;
    std::string sep_;
};

Split::Split(std::string const &str, std::string const &sep):
    str_(str), sep_(sep)
{
}

std::vector<std::string> Split::compute()
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

void Split::push_back(std::vector<std::string> &list,
    std::string const &s)
{
    if (sep_ != "" || s != "") {
        list.push_back(s);
    }
}

std::vector<std::string> split(std::string const &s,
    std::string sep)
{
    return Split(s, sep).compute();
}

}
@

@<replace@>=
namespace ebt {

std::string replace(std::string s, std::string pattern,
    std::string replacement);

}
@

@<replace impl@>=
namespace ebt {

std::string replace(std::string s, std::string pattern,
    std::string replacement)
{
    std::vector<std::string> parts = ebt::split(s, pattern);
    return ebt::join(parts, replacement);
}

}
@

@<join@>=
namespace ebt {

template <class Iterable>
std::string join(Iterable &&iter, std::string const &sep)
{
    std::ostringstream oss;

    for (auto &i: iter) {
        oss << i << sep;
    }

    if (oss.str().size() >= sep.size()) {
        return oss.str().erase(oss.str().size() - sep.size());
    } else {
        return "";
    }
}

}
@

@<test_join.cc@>=
#include "ebt.h"
#include <vector>
#include <iostream>

int main()
{
    std::vector<int> a {0, 1, 2};
    std::cout << ebt::join(a, "-") << std::endl;
    return 0;
}
@

@<format@>=
namespace ebt {

inline std::ostream & format(std::ostream &os, std::string fmt)
{
    return os << fmt;
}

template <typename T, typename... Args>
std::ostream & format(std::ostream &os, std::string fmt,
    T const &t, Args const &... args)
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
std::string format(std::string fmt, Args const &... args)
{
    std::ostringstream oss;
    format(oss, std::move(fmt), args...);
    return oss.str();
}

}
@

@<test_format.cc@>=
#include <iostream>
#include "ebt.h"

int main()
{
    std::cout << ebt::format("{} {} {}", 1, 2, 3) << std::endl;
    std::cout << ebt::format("{{}}", 1, 2, 3) << std::endl;
    return 0;
}
@

@<to_string@>=
namespace std {

inline std::string const & to_string(std::string const &s)
{
    return s;
}

template <class U, class V>
std::string to_string(std::pair<U, V> const &p)
{
    std::ostringstream oss;
    oss << p;
    return oss.str();
}

}
@

@<split utf-8 chars@>=
namespace ebt {

std::vector<std::string> split_utf8_chars(std::string const &s);

}
@

@<split utf-8 chars impl@>=
namespace ebt {

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
@

@<test_split_utf8.cc@>=
#include "ebt.h"

int main()
{
    for (auto &s: ebt::split_utf8_chars("這是測試")) {
        std::cout << s << std::endl;
    }

    return 0;
}
@

\section{Utility}

\subsection{Either}

@<either@>=
namespace ebt {

template <class T>
struct Left {
    T value;
};

template <class T>
Left<T> left(T t)
{
    return Left<T> { std::move(t) };
}

template <class T>
struct Right {
    T value;
};

template <class T>
Right<T> right(T t)
{
    return Right<T> { std::move(t) };
}

template <class L, class R>
struct Either {
    Either()
        : is_left_(true)
    {}

    explicit Either(Left<L> left)
        : left_(std::move(left.value)), is_left_(true)
    {
    }

    explicit Either(Right<R> right)
        : right_(std::move(right.value)), is_left_(false)
    {
    }

    bool is_left() const
    {
        return is_left_;
    }

    bool is_right() const
    {
        return !is_left_;
    }

    L const & left() const
    {
        return left_;
    }

    L & left()
    {
        return left_;
    }

    R const & right() const
    {
        return right_;
    }

    R & right()
    {
        return right_;
    }

    bool operator==(Either const &that) const
    {
        if (this->is_left() && that.is_left()) {
            return this->left() == that.left();
        } else if (this->is_right() && that.is_right()) {
            return this->right() == that.right();
        } else {
            return false;
        }
    }

private:
    L left_;
    R right_;
    bool is_left_;
};

template <class L, class R>
std::ostream& operator<<(std::ostream &os, Either<L, R> const &e)
{
    if (e.is_left()) {
        os << "l:" << e.left();
    } else {
        os << "r:" << e.right();
    }
    return os;
}

}

namespace std {

template <class Left, class Right>
struct hash<ebt::Either<Left, Right>> {
    size_t operator()(ebt::Either<Left, Right> const &e) const noexcept
    {
        if (e.is_left()) {
            return hash<Left>()(e.left());
        } else {
            return hash<Right>()(e.right());
        }
    }
};

}
@

\subsection{Option}

@<option@>=
namespace ebt {

template <class T>
class Option {
public:
    Option()
    {}

    explicit Option(T t)
        : some_(right(std::move(t)))
    {}

    bool has_none() const
    {
        return some_.is_left();
    }

    bool has_some() const
    {
        return some_.is_right();
    }

    T const & some() const
    {
        return some_.right();
    }

    T & some()
    {
        return some_.right();
    }

private:
    struct None {};

    Either<None, T> some_;
};

template <class T>
Option<T> some(T t)
{
    return Option<T>(std::move(t));
}

template <class T>
Option<T> none()
{
    return Option<T>();
}

}
@

\subsection{Universal Reference}

@<uni ref@>=
namespace ebt {

template <class T>
class RuntimeUniRef {
public:
    RuntimeUniRef(T const &t)
        : t_(&t), own_(false)
    {}

    RuntimeUniRef(T &&t)
        : t_(new T(std::move(t))), own_(true)
    {}

    RuntimeUniRef(RuntimeUniRef const &that)
        : t_(new T(*that.t_)), own_(true)
    {}

    RuntimeUniRef(RuntimeUniRef &&that)
        : t_(that.t_), own_(that.own_)
    {
        that.own_ = false;
    }

    ~RuntimeUniRef()
    {
        if (own_) {
            delete t_;
        }
    }

    RuntimeUniRef & operator=(RuntimeUniRef const &that)
    {
        if (own_) {
            delete t_;
        }

        t_ = new T(*that.t_);
        own_ = true;
        return *this;
    }

    RuntimeUniRef & operator=(RuntimeUniRef &&that)
    {
        if (own_) {
            delete t_;
        }

        t_ = that.t_;
        own_ = that.own_;

        that.own_ = false;

        return *this;
    }

    T & get()
    {
        return *const_cast<T*>(t_);
    }

    T const & get() const
    {
        return *t_;
    }

private:
    T const *t_;
    bool own_;
};

template <class T, bool is_default_constructible>
class UniRefImpl;

template <class T>
class UniRef
    : public UniRefImpl<T, std::is_default_constructible<T>::value> {

public:
    UniRef() = default;

    UniRef(T t)
        : UniRefImpl<T, std::is_default_constructible<T>::value>(
            std::forward<T>(t))
    {}

    bool operator==(UniRef const &that) const
    {
        return this->get() == that.get();
    }
};

template <class T>
class UniRefImpl<T, true> {
public:
    UniRefImpl() = default;

    UniRefImpl(T value)
        : value_(std::move(value))
    {}

    T & get()
    {
        return value_;
    }

    T const & get() const
    {
        return value_;
    }

    explicit operator bool() const
    {
        return true;
    }

private:
    T value_;
};

template <class T>
class UniRefImpl<T, false> {
public:
    UniRefImpl()
        : value_(nullptr)
    {}

    UniRefImpl(T value)
        : value_(new T(std::move(value)))
    {}

    T & get()
    {
        return *value_;
    }

    T const & get() const
    {
        return *value_;
    }

    explicit operator bool() const
    {
        return value_ != nullptr;
    }

private:
    std::shared_ptr<T> value_;
};

template <class T>
class UniRefImpl<T const &, false> {
public:
    UniRefImpl()
        : value_(nullptr)
    {}

    UniRefImpl(T const &value)
        : value_(&value)
    {}

    T const & get() const
    {
        return *value_;
    }

private:
    T const *value_;
};

template <class T>
UniRef<T> make_uni(T &&t)
{
    return UniRef<T>(std::forward<T>(t));
}

template <class T>
std::ostream & operator<<(std::ostream &os, ebt::UniRef<T> const &t)
{
    os << t.get();
    return os;
}

}

namespace std {

template <class T>
struct hash<ebt::UniRef<T>> {
    size_t operator()(ebt::UniRef<T> const &ref) const noexcept
    {
        hash<typename std::decay<T>::type> hasher;
        return hasher(ref.get());
    }
};

}
@

@<test_uni_ref.cc@>=
#include <functional>
#include "ebt.h"

void test1()
{
    ebt::UniRef<std::reference_wrapper<int>> a;

    int i = 3;

    a = ebt::UniRef<std::reference_wrapper<int>>(i);

    std::cout << a.get() << std::endl;
}

void test2()
{
    ebt::UniRef<int const &> a;

    int i = 3;

    a = ebt::UniRef<int const &>(i);

    std::cout << a.get() << std::endl;
}

void test3()
{
    ebt::UniRef<std::vector<int>> a = ebt::UniRef<std::vector<int>>(
        std::vector<int>({1, 2, 3}));

    std::cout << a.get()[0] << std::endl;
    std::cout << a.get()[1] << std::endl;
    std::cout << a.get()[2] << std::endl;
}

int main()
{
    test1();
    test2();
    test3();
    return 0;
}
@

\subsection{Pair and Tuple}

@<tuple utility@>=
namespace std {

template <size_t i, class... Args>
struct hash_tuple {
    size_t& operator()(size_t &seed, tuple<Args...> const &t) const
    {
        hash_tuple<i-1, Args...> init;
        hash<typename tuple_element<i, tuple<Args...>>::type> hasher;
        return ebt::hash_combine(init(seed, t), hasher(get<i>(t)));
    }
};

template <class... Args>
struct hash_tuple<0, Args...> {
    size_t & operator()(size_t &seed, tuple<Args...> const &t) const
    {
        hash<typename tuple_element<0, tuple<Args...>>::type> hasher;
        return ebt::hash_combine(seed, hasher(get<0>(t)));
    }
};

template <class... Args>
struct hash<tuple<Args...>> {
    size_t operator()(tuple<Args...> const &t) const noexcept
    {
        size_t seed = 0;
        return hash_tuple<tuple_size<tuple<Args...>>::value - 1,
            Args...>()(seed, t);
    }
};

template <size_t i, class... Args>
struct print_tuple {
    ostream& operator()(ostream &os, tuple<Args...> const &t) const
    {
        print_tuple<i-1, Args...> print;
        print(os, t) << ", " << get<i>(t);
        if (i == tuple_size<tuple<Args...>>::value - 1) {
            os << ")";
        }
        return os;
    }
};

template <class... Args>
struct print_tuple<0, Args...> {
    ostream& operator()(ostream &os, tuple<Args...> const &t) const
    {
        return os << "(" << get<0>(t);
    }
};

template <class... Args>
ostream & operator<<(ostream &os, tuple<Args...> const &t)
{
    return print_tuple<tuple_size<tuple<Args...>>::value - 1,
        Args...>()(os, t);
}

}
@

@<test_print_tuple.cc@>=
#include <iostream>
#include <tuple>
#include "ebt.h"

int main()
{
    std::tuple<int, int, int> t {0, 1, 2};

    std::cout << t << std::endl;

    return 0;
}
@

@<pair utility@>=
namespace std {

template <class U, class V>
struct hash<pair<U, V>> {
    size_t operator()(std::pair<U, V> const &p) const noexcept
    {
        hash<U> v_hasher;
        hash<V> u_hasher;
        size_t seed = 0;
        ebt::hash_combine(seed, v_hasher(p.first));
        ebt::hash_combine(seed, u_hasher(p.second));
        return seed;
    }
};

template <class U, class V>
ostream & operator<<(ostream &os, pair<U, V> const &p)
{
    os << "(" << p.first << ", " << p.second << ")";
    return os;
}

}
@

\subsection{Vector}

@<vector utility@>=
namespace std {

template <class T>
struct hash<vector<T>> {
    size_t operator()(vector<T> const &v) const noexcept
    {
        size_t result = 0;
        hash<T> e_hasher;
        for (auto &e: v) {
            ebt::hash_combine(result, e_hasher(e));
        }
        return result;
    }
};

template <class T>
ostream & operator<<(ostream &os, std::vector<T> const &vec)
{
    /*
    return os << "[" << ebt::join(ebt::map(vec,
            [](T const &t) { return to_string(t); }), ", ")
        << "]";
    */
    return os << "[" << ebt::join(vec, ", ") << "]";
}

template <class T>
string to_string(vector<T> const &vec)
{
    std::ostringstream oss;
    oss << vec;
    return oss.str();
}

}

namespace ebt {

template <class T>
class VectorParser {
public:
    VectorParser(std::istream &is)
        : is_(is)
    {}

    std::vector<T> parse()
    {
        std::vector<T> result;
        expect(is_, '[');
        is_.get();
        if (is_.peek() != ']') {
            while (1) {
                T t;
                ebt::parse(is_, t);
                result.push_back(std::move(t));
                if (is_.peek() == ',') {
                    expect(is_, ',');
                    is_.get();
                    expect(is_, ' ');
                    is_.get();
                } else {
                    break;
                }
            }
        }
        expect(is_, ']');
        is_.get();
        return result;
    }

private:
    std::istream &is_;
};

template <class T>
std::istream & parse(std::istream &is, std::vector<T> &result)
{
    result = VectorParser<T>(is).parse();
    return is;
}

}
@

\subsection{List}

@<list utility@>=
namespace std {

template <class T>
ostream & operator<<(ostream &os, std::list<T> const &list)
{
    /*
    return os << "[" << ebt::join(ebt::map(list,
            [](T const &t) { return to_string(t); }), ", ")
        << "]";
    */
    return os << "[" << ebt::join(list, ", ") << "]";
}

}
@

\subsection{Unordered Map}

@<unordered_map utility@>=
namespace ebt {

template <class K, class V>
bool in(K const &key, std::unordered_map<K, V> const &map)
{
    return map.find(key) != map.end();
}

template <class K, class V>
Option<V> get(std::unordered_map<K, V> const &map, K const &key)
{
    if (map.find(key) == map.end()) {
        return none<V>();
    } else {
        return some(map.at(key));
    }
}

template <class K, class V>
V const & get(std::unordered_map<K, V> const &map, K const &key,
    V const &default_)
{
    if (map.find(key) == map.end()) {
        return default_;
    } else {
        return map.at(key);
    }
}

}

namespace std {

template <class K, class V>
ostream & operator<<(ostream &os, std::unordered_map<K, V> const &map)
{
    return os << "{" << ebt::join(ebt::map(map,
        [](std::pair<const K, V> const &p) {
            using std::to_string;
            return to_string(p.first) + ": "
                + to_string(p.second);
        }), ", ") << "}";
}

template <class K, class V>
struct hash<unordered_map<K, V>> {
    size_t operator()(unordered_map<K, V> const &map) const noexcept
    {
        size_t seed = 0;

        hash<K> k_hasher;
        hash<V> v_hasher;

        for (auto &p: map) {
            seed ^= ebt::hash_combine(k_hasher(p.first),
                v_hasher(p.second));
        }

        return seed;
    }
};

}
@

\subsection{Unordered Set Utility}

@<unordered_set utility@>=
namespace std {

template <class T>
struct hash<unordered_set<T>> {
    size_t operator()(unordered_set<T> const &set) const noexcept
    {
        size_t seed = 0;

        hash<T> t_hasher;

        for (auto &e: set) {
            seed ^= t_hasher(e);
        }

        return seed;
    }
};

}

namespace ebt {

template <class T>
bool in(T const &t, std::unordered_set<T> const &set)
{
    return set.find(t) != set.end();
}

}
@

\subsection{Max Heap}

@<max heap@>=
namespace ebt {

template <class V, class K>
class MaxHeap {
private:
    std::vector<std::pair<V, K>> data_;
    std::unordered_map<V, int> index_;

    int parent(int i)
    {
        return i / 2;
    }

    int left(int i)
    {
        return 2 * i;
    }

    int right(int i)
    {
        return 2 * i + 1;
    }

    MaxHeap & max_heapify(int index)
    {
        int i = index;
        while (0 <= i && i < data_.size()) {
            int max = i;
            if (left(i) < data_.size()
                    && data_[left(i)].second > data_[max].second) {
                max = left(i);
            }
            if (right(i) < data_.size()
                    && data_[right(i)].second > data_[max].second) {
                max = right(i);
            }

            if (max == i) {
                break;
            } else {
                using std::swap;
                swap(index_[data_[i].first], index_[data_[max].first]);
                swap(data_[i], data_[max]);
                i = max;
            }
        }
        return *this;
    }

public:
    int size() const
    {
        return data_.size();
    }

    MaxHeap & insert(V t, K value)
    {
        data_.resize(data_.size() + 1);
        index_[t] = data_.size() - 1;
        data_.back() = std::make_pair(t, value);
        increase_key(t, value);
        return *this;
    }

    MaxHeap & increase_key(V t, K value)
    {
        int i = index_.at(t);
        data_[i].second = value;
        while (0 <= i && i < data_.size()
                && value > data_[parent(i)].second) {
            using std::swap;
            swap(index_[data_[i].first], index_[data_[parent(i)].first]);
            swap(data_[i], data_[parent(i)]);
            i = parent(i);
        }
        return *this;
    }

    V extract_max()
    {
        V result = std::move(data_.front().first);
        using std::swap;
        swap(data_.back(), data_.front());
        index_[data_.front().first] = 0;
        index_.erase(result);
        data_.resize(data_.size() - 1);
        max_heapify(0);
        return result;
    }
};

}
@


\subsection{Hash}

@<hash combine@>=
namespace ebt {

inline size_t & hash_combine(size_t &seed, size_t value)
{
    seed ^= value + 0x9e3779b9
        + (seed >> 6) + (seed << 2);
    return seed;
}

}
@

\section{Iterable Tools}

\subsection{Range}

@<range@>=
namespace ebt {

class RangeIterator : public std::iterator<std::input_iterator_tag, int> {
public:
    RangeIterator(int current, int inc=1);
    RangeIterator& operator++();
    int const & operator*() const;
    bool operator!=(RangeIterator const &that) const;

private:
    int current_;
    int inc_;
};

class Range {
public:
    using const_iterator = RangeIterator;
    using value_type = int;

    Range(int start, int end, int inc=1);

    RangeIterator begin() const;
    RangeIterator end() const;

    unsigned int size() const;

private:
    int start_;
    int end_;
    int inc_;
};

}
@

@<range impl@>=
namespace ebt {

RangeIterator::RangeIterator(int current, int inc)
    : current_(current), inc_(inc)
{
}

RangeIterator& RangeIterator::operator++()
{
    current_ += inc_;
    return *this;
}

int const & RangeIterator::operator*() const
{
    return current_;
}

bool RangeIterator::operator!=(RangeIterator const &that) const
{
    return current_ != that.current_;
}

Range::Range(int start, int end, int inc)
    : start_(start), end_(end), inc_(inc)
{
}

RangeIterator Range::begin() const
{
    return RangeIterator(start_, inc_);
}

RangeIterator Range::end() const
{
    return RangeIterator(end_, inc_);
}

unsigned int Range::size() const
{
    return end_ - start_;
}

}
@

\subsection{Zip}

@<zip@>=
namespace ebt {

template <class Iter1, class Iter2>
class ZipIterator : public std::iterator<
    std::input_iterator_tag,
    std::pair<UniRef<decltype(*std::declval<Iter1>())>,
        UniRef<decltype(*std::declval<Iter2>())>>> {
public:
    ZipIterator(Iter1 iter1, Iter2 iter2)
        : iter1_(iter1), iter2_(iter2)
    {}

    ZipIterator & operator++()
    {
        ++iter1_;
        ++iter2_;
        return *this;
    }

    bool operator!=(ZipIterator const &that) const
    {
        return this->iter1_ != that.iter1_ && this->iter2_ != that.iter2_;
    }

    typename ZipIterator::value_type & operator*()
    {
        value_ = std::make_pair(ebt::make_uni(*iter1_), ebt::make_uni(*iter2_));
        return value_;
    }

private:
    Iter1 iter1_;
    Iter2 iter2_;
    typename ZipIterator::value_type value_;
};

template <class Iterable1, class Iterable2>
class ZipIterable {
public:
    using iterator = ZipIterator<
        typename std::decay<Iterable1>::type::iterator,
        typename std::decay<Iterable2>::type::iterator>;

    using const_iterator = ZipIterator<
        typename std::decay<Iterable1>::type::const_iterator,
        typename std::decay<Iterable2>::type::const_iterator>;

    using value_type = typename const_iterator::value_type;

    ZipIterable(Iterable1 &&iterable1, Iterable2 &&iterable2)
        : iterable1_(std::forward<Iterable1>(iterable1))
        , iterable2_(std::forward<Iterable2>(iterable2))
    {}

    iterator begin()
    {
        return iterator(iterable1_.begin(), iterable2_.begin());
    }

    iterator end()
    {
        return iterator(iterable1_.end(), iterable2_.end());
    }

    const_iterator begin() const
    {
        return const_iterator(iterable1_.begin(), iterable2_.begin());
    }

    const_iterator end() const
    {
        return const_iterator(iterable1_.end(), iterable2_.end());
    }

private:
    Iterable1 iterable1_;
    Iterable2 iterable2_;
};

template <class Iterable1, class Iterable2>
ZipIterable<Iterable1, Iterable2> zip(Iterable1 &&iterable1,
    Iterable2 &&iterable2)
{
    return ZipIterable<Iterable1, Iterable2>(
        std::forward<Iterable1>(iterable1),
        std::forward<Iterable2>(iterable2));
}

}
@

@<test_zip.cc@>=
#include <vector>
#include <string>
#include "ebt.h"

int main()
{
    std::vector<int> a {0, 1, 2};
    std::vector<std::string> b {"a", "b", "c"};

    for (auto &p: ebt::zip(a, b)) {
        std::cout << p.first.get() << ", " << p.second.get() << std::endl;
    }

    return 0;
}
@

\subsection{Cartesian Product}

We assume an iterator return a reference.  Therefore,
the \texttt{value\_type} is a pair of \texttt{UniRef}.
We implement the product in a lazy way, meaning
that the pair is not generated until the iterable is iterated.

@<product@>=
namespace ebt {

template <class OuterIterable, class InnerIterable>
class ProductIterator : public std::iterator<std::input_iterator_tag,
    std::pair<UniRef<decltype(*std::declval<
            typename OuterIterable::const_iterator>())>,
        UniRef<decltype(*std::declval<
            typename InnerIterable::const_iterator>())>>> {

    using Outer = OuterIterable;
    using Inner = InnerIterable;

    typename Outer::const_iterator outer_iter_;
    typename Inner::const_iterator inner_iter_;
    Outer const *outer_iterable_;
    Inner const *inner_iterable_;

    typename ProductIterator::value_type value_;

public:
    ProductIterator() = default;

    ProductIterator(typename Outer::const_iterator outer_iter,
        typename Inner::const_iterator inner_iter,
        Outer const &outer_iterable,
        Inner const &inner_iterable)
        : outer_iter_(std::move(outer_iter))
        , inner_iter_(std::move(inner_iter))
        , outer_iterable_(&outer_iterable)
        , inner_iterable_(&inner_iterable)
    {}

    typename ProductIterator::value_type const & operator*()
    {
        value_ = typename ProductIterator::value_type(
            *outer_iter_, *inner_iter_);
        return value_;
    }

    ProductIterator & operator++()
    {
        ++inner_iter_;
        if (inner_iter_ == inner_iterable_->end()) {
            ++outer_iter_;
            if (outer_iter_ != outer_iterable_->end()) {
                inner_iter_ = inner_iterable_->begin();
            }
        }
        return *this;
    }

    bool operator==(ProductIterator const &that) const
    {
        return outer_iter_ == that.outer_iter_
            && inner_iter_ == that.inner_iter_;
    }

    bool operator!=(ProductIterator const &that) const
    {
        return !(*this == that);
    }
};

template <class OuterIterable, class InnerIterable>
class ProductIterable {
private:
    OuterIterable outer_iterable_;
    InnerIterable inner_iterable_;

public:
    using const_iterator
        = ProductIterator<typename std::decay<OuterIterable>::type,
        typename std::decay<InnerIterable>::type>;
    using value_type = typename const_iterator::value_type;

    ProductIterable(OuterIterable &&outer_iterable,
        InnerIterable &&inner_iterable)
        : outer_iterable_(std::forward<OuterIterable>(outer_iterable))
        , inner_iterable_(std::forward<InnerIterable>(inner_iterable))
    {}

    const_iterator begin() const
    {
        if (outer_iterable_.begin() == outer_iterable_.end()
                || inner_iterable_.begin() == inner_iterable_.end()) {
            return end();
        } else {
            return const_iterator(
                outer_iterable_.begin(), inner_iterable_.begin(),
                outer_iterable_, inner_iterable_);
        }
    }

    const_iterator end() const
    {
        return const_iterator(
            outer_iterable_.end(), inner_iterable_.end(),
            outer_iterable_, inner_iterable_);
    }
};

template <class OuterIterable, class InnerIterable>
ProductIterable<OuterIterable, InnerIterable>
product(OuterIterable &&outer_iterable, InnerIterable &&inner_iterable)
{
    return ProductIterable<OuterIterable, InnerIterable>(
        std::forward<OuterIterable>(outer_iterable),
        std::forward<InnerIterable>(inner_iterable));
}

}
@

@<test_product.cc@>=
#include <vector>
#include <string>
#include <iostream>
#include "ebt.h"

void test1()
{
    std::vector<std::string> a {"1", "2", "3"};
    std::vector<std::string> b {"a", "b", "c"};

    for (auto e: ebt::product(a, b)) {
        std::cout << e << std::endl;
    }
}

void test2()
{
    std::vector<int> a {1, 2, 3};
    std::vector<std::string> b {"a", "b", "c"};

    for (auto e: ebt::product(a, b)) {
        std::cout << e << std::endl;
    }
}

void test3()
{
    std::vector<int> a {1, 2, 3};
    std::vector<std::string> b {"a", "b", "c"};

    for (auto e: ebt::product(a, b)) {
        std::cout << e << std::endl;
    }
}

void test4()
{
    std::vector<int> a {1, 2, 3};

    for (auto e: ebt::product(a, a)) {
        std::cout << e << std::endl;
    }
}

void test5()
{
    std::vector<int> a {1, 2, 3};

    for (auto e: ebt::product(a, std::vector<int>())) {
        std::cout << e << std::endl;
    }

    for (auto e: ebt::product(std::vector<int>(), a)) {
        std::cout << e << std::endl;
    }

    for (auto e: ebt::product(std::vector<int>(), std::vector<int>())) {
        std::cout << e << std::endl;
    }
}

int main()
{
    test1();
    test2();
    test3();
    test4();
    test5();

    return 0;
}
@

\subsection{Map}

The function that maps the elements is copied to every iterator
in case the function has its own internal state.  The result
type the function has to be copy-constructible and copy-assignable.
We implement it in a lazy way, meaning that the result of the
function is not generated until the iterable is iterated.

@<map@>=
namespace ebt {

template <class Iterator, class Function>
class MapIterator : public std::iterator<std::input_iterator_tag,
    typename std::decay<
        decltype(std::declval<Function>()(*std::declval<Iterator>()))
    >::type> {

private:
    Iterator iter_;
    Function const *f_;
    UniRef<decltype(std::declval<Function>()(*std::declval<Iterator>()))>
        value_;

public:
    MapIterator() = default;

    MapIterator(Iterator iter, Function const &f)
        : iter_(std::move(iter)), f_(&f)
    {}

    auto operator*() -> decltype(value_.get())
    {
        value_ = make_uni((*f_)(*iter_));
        return value_.get();
    }

    MapIterator & operator++()
    {
        ++iter_;
        return *this;
    }

    bool operator==(MapIterator const &that) const
    {
        return iter_ == that.iter_;
    }

    bool operator!=(MapIterator const &that) const
    {
        return !(*this == that);
    }
};

template <class Iterable, class Function>
class MapIterable {
public:
    using const_iterator = MapIterator<
        typename std::decay<Iterable>::type::const_iterator, Function>;
    using value_type = typename const_iterator::value_type;

    MapIterable(Iterable &&iterable, Function f)
        : iterable_(std::forward<Iterable>(iterable)), f_(std::move(f))
    {}

    const_iterator begin() const
    {
        return const_iterator(iterable_.begin(), f_);
    }

    const_iterator end() const
    {
        return const_iterator(iterable_.end(), f_);
    }

private:
    Iterable iterable_;
    Function f_;
};

template <class Iterable, class Function>
MapIterable<Iterable, Function> map(Iterable &&iterable, Function f)
{
    return MapIterable<Iterable, Function>(
        std::forward<Iterable>(iterable), std::move(f));
}

}
@

@<test_map.cc@>=
#include <vector>
#include <iostream>
#include "ebt.h"

int main()
{
    std::vector<std::string> a {"a", "aa", "aaa", "aaaa"};

    for (auto e: ebt::map(a,
            [](std::string const &s) { return s.size(); })) {
        std::cout << e << std::endl;
    }

    return 0;
}
@

\subsection{Filter}

@<filter@>=
namespace ebt {

template <class Iterator, class Predicate>
class FilterIterator : public std::iterator<std::input_iterator_tag,
    typename Iterator::value_type> {

private:
    Iterator iter_;
    Iterator end_;
    Predicate const *p_;
    UniRef<decltype(*std::declval<Iterator>())> value_;

public:
    FilterIterator() = default;

    FilterIterator(Iterator iter, Iterator end, Predicate const &p)
        : iter_(std::move(iter))
        , end_(std::move(end))
        , p_(&p)
    {
        while (iter_ != end_ && !(*p_)(*iter_)) {
            ++iter_;
        }
    }

    auto operator*() -> decltype(value_.get())
    {
        value_ = make_uni(*iter_);
        return value_.get();
    }

    FilterIterator & operator++()
    {
        if (iter_ != end_) {
            ++iter_;
        }
        while (iter_ != end_ && !(*p_)(*iter_)) {
            ++iter_;
        }
        return *this;
    }

    bool operator==(FilterIterator const &that) const
    {
        return iter_ == that.iter_;
    }

    bool operator!=(FilterIterator const &that) const
    {
        return !(*this == that);
    }
};

template <class Iterable, class Predicate>
class FilterIterable {
public:
    using const_iterator = FilterIterator<
        typename std::decay<Iterable>::type::const_iterator, Predicate>;
    using value_type = typename const_iterator::value_type;

    FilterIterable(Iterable &&iterable, Predicate p)
        : iterable_(std::forward<Iterable>(iterable))
        , p_(std::move(p))
    {}

    const_iterator begin() const
    {
        return const_iterator(iterable_.begin(), iterable_.end(), p_);
    }

    const_iterator end() const
    {
        return const_iterator(iterable_.end(), iterable_.end(), p_);
    }

private:
    Iterable iterable_;
    Predicate p_;
};

template <class Iterable, class Predicate>
FilterIterable<Iterable, Predicate> filter(Iterable &&iterable, Predicate p)
{
    return FilterIterable<Iterable, Predicate>(
        std::forward<Iterable>(iterable), std::move(p));
}

}
@

@<test_filter.cc@>=
#include <vector>
#include <iostream>
#include "ebt.h"

void test1()
{
    std::vector<int> a {0, 1, 2, 3, 4, 5};

    for (auto &e: ebt::filter(a, [](int i) { return i % 2 == 0; })) {
        std::cout << e << std::endl;
    }
}

void test2()
{
    std::vector<std::string> a {"a", "aa", "aaa", "aaaa"};

    for (auto e: ebt::filter(ebt::map(a,
            [](std::string const &s) { return s.size(); }),
            [](int i) { return i % 2 == 0; })) {
        std::cout << e << std::endl;
    }
}

int main()
{
    test1();
    test2();
    return 0;
}
@

@<chain@>=
namespace ebt {

template <class Iterable>
class ChainIterator : public std::iterator<std::input_iterator_tag,
    typename Iterable::value_type::value_type> {

    using Outer = Iterable;
    using Inner = typename Outer::value_type;

    using UniInner = UniRef<decltype(
        *std::declval<typename Outer::const_iterator>())>;

    Outer const *outer_iterable_;
    UniInner inner_iterable_;
    typename Outer::const_iterator outer_iter_;
    typename Inner::const_iterator inner_iter_;

    UniRef<decltype(*std::declval<typename Inner::const_iterator>())>
        value_;

public:
    ChainIterator() = default;

    ChainIterator(Outer const &outer_iterable,
        typename Outer::const_iterator outer_iter)
        : outer_iterable_(&outer_iterable)
        , outer_iter_(std::move(outer_iter))
    {
        while (outer_iter_ != outer_iterable_->end()) {
            inner_iterable_ = UniInner(*outer_iter_);
            inner_iter_ = inner_iterable_.get().begin();
            if (inner_iter_ != inner_iterable_.get().end()) {
                break;
            }
            ++outer_iter_;
        }
    }

    auto operator*() -> decltype(value_.get())
    {
        value_ = make_uni(*inner_iter_);
        return value_.get();
    }

    ChainIterator & operator++()
    {
        ++inner_iter_;
        if (inner_iter_ == inner_iterable_.get().end()) {
            ++outer_iter_;
            while (outer_iter_ != outer_iterable_->end()) {
                inner_iterable_ = UniInner(*outer_iter_);
                inner_iter_ = inner_iterable_.get().begin();
                if (inner_iter_ != inner_iterable_.get().end()) {
                    break;
                }
                ++outer_iter_;
            }
        }
        return *this;
    }

    bool operator==(ChainIterator const &that) const
    {
        if (outer_iter_ == outer_iterable_->end()) {
            return true;
        } else {
            return false;
        }
    }

    bool operator!=(ChainIterator const &that) const
    {
        return !(*this == that);
    }
};

template <class Iterable>
class ChainIterable {
public:
    using const_iterator = ChainIterator<
        typename std::decay<Iterable>::type>;
    using value_type = typename const_iterator::value_type;

    ChainIterable(Iterable &&iterable)
        : iterable_(std::forward<Iterable>(iterable))
    {}

    const_iterator begin() const
    {
        return const_iterator(iterable_, iterable_.begin());
    }

    const_iterator end() const
    {
        return const_iterator(iterable_, iterable_.end());
    }

private:
    Iterable iterable_;
};

template <class Iterable>
ChainIterable<Iterable> chain(Iterable &&iterable)
{
    return ChainIterable<Iterable>(std::forward<Iterable>(iterable));
}

template <class Iter1, class Iter2>
class ChainIterator2 : public std::iterator<std::input_iterator_tag,
    typename std::decay<decltype(*std::declval<Iter1>())>::type> {
private:
    Iter1 iter1_;
    Iter1 iter1_end_;
    Iter2 iter2_;

    struct promote {
        using v1 = decltype(*std::declval<Iter1>());
        using v2 = decltype(*std::declval<Iter2>());

        using return_type
            = typename std::conditional<std::is_same<v1, v2>::value, v1,
                typename std::conditional<
                    std::is_same<typename std::remove_reference<v2>::type,
                        v1>::value,
                    v1, typename std::remove_reference<v1>::type
                >::type>::type;
    };

    UniRef<typename std::remove_cv<
        typename promote::return_type>::type> value_;

public:
    ChainIterator2() = default;

    ChainIterator2(Iter1 iter1, Iter1 iter1_end, Iter2 iter2)
        : iter1_(std::move(iter1))
        , iter1_end_(std::move(iter1_end))
        , iter2_(std::move(iter2))
    {}

    ChainIterator2 & operator++()
    {
        if (iter1_ != iter1_end_) {
            ++iter1_;
        } else {
            ++iter2_;
        }

        return *this;
    }

    auto operator*() -> decltype(value_.get())
    {
        if (iter1_ != iter1_end_) {
            value_ = decltype(value_)(*iter1_);
        } else {
            value_ = decltype(value_)(*iter2_);
        }
        return value_.get();
    }

    bool operator==(ChainIterator2 const &that) const
    {
        return iter1_ == that.iter1_ && iter2_ == that.iter2_;
    }

    bool operator!=(ChainIterator2 const &that) const
    {
        return !(*this == that);
    }
};

template <class Iterable1, class Iterable2>
class ChainIterable2 {
private:
    Iterable1 iterable1_;
    Iterable2 iterable2_;

public:
    using const_iterator
        = ChainIterator2<
            typename std::decay<Iterable1>::type::const_iterator,
            typename std::decay<Iterable2>::type::const_iterator>;
    using value_type = typename const_iterator::value_type;

    ChainIterable2(Iterable1 &&iterable1, Iterable2 &&iterable2)
        : iterable1_(std::forward<Iterable1>(iterable1))
        , iterable2_(std::forward<Iterable2>(iterable2))
    {}

    const_iterator begin() const
    {
        return const_iterator(iterable1_.begin(), iterable1_.end(),
            iterable2_.begin());
    }

    const_iterator end() const
    {
        return const_iterator(iterable1_.end(), iterable1_.end(),
            iterable2_.end());
    }
};

template <class Iterable1, class Iterable2>
ChainIterable2<Iterable1, Iterable2>
chain(Iterable1 &&iterable1, Iterable2 &&iterable2)
{
    return ChainIterable2<Iterable1, Iterable2>(
        std::forward<Iterable1>(iterable1),
        std::forward<Iterable2>(iterable2));
}

}
@

@<test_chain.cc@>=
#include <iostream>
#include <vector>
#include <string>
#include "ebt.h"

void test1()
{
    std::vector<std::vector<std::string>> a {
        {"a", "aa"}, {"b", "bb"}, {"c", "cc"}};

    for (auto &e: ebt::chain(a)) {
        std::cout << e << std::endl;
    }
}

void test2()
{
    std::vector<int> a {1, 2, 3};

    auto c = ebt::chain(ebt::map(a,
      [](int i) {
          std::vector<std::string> result;

          for (int j = 0; j < i; ++j) {
              result.push_back(std::to_string(i));
          }

          return result;
      }));

    for (auto &e: c) {
        std::cout << e << std::endl;
    }
}

void test3()
{
    std::vector<int> a {1, 2, 3};

    auto c = ebt::chain(ebt::map(a,
        [](int i) { return std::vector<std::string>(); }));

    for (auto &&e: c) {
        std::cout << e << std::endl;
    }
}

void test4()
{
    std::vector<int> a {1, 2, 3};
    std::vector<int> b {4, 5, 6};

    for (auto &e: ebt::chain(a, b)) {
        std::cout << e << std::endl;
    }
}

void test5()
{
    std::vector<int> a {1};
    std::vector<std::string> b { "aa", "aaa" };
    auto iter = ebt::chain(a, ebt::map(b,
        [](std::string const &s) { return s.size(); }));
    for (auto &&e: iter) {
        std::cout << e << std::endl;
    }
}

int main()
{
    test1();
    test2();
    test3();
    test4();
    test5();

    return 0;
}
@

\subsection{N-gram}

@<ngram@>=
namespace ebt {

template <class Iterator>
class NGramIterator : public std::iterator<
    std::input_iterator_tag,
    std::list<typename Iterator::value_type>> {

public:
    NGramIterator() = default;

    NGramIterator(Iterator iter, Iterator end, int n)
        : iter_(iter), end_(end), n_(n)
    {
        for (int i = 0; i < n_ - 1; ++i) {
            if (iter_ != end_) {
                value_.push_back(*iter_);
                ++iter_;
            }
        }
        if (iter_ != end_) {
            value_.push_back(*iter_);
        }
    }

    NGramIterator & operator++()
    {
        if (iter_ != end_) {
            ++iter_;
        }
        if (iter_ != end_) {
            value_.pop_front();
            value_.push_back(*iter_);
        }
        return *this;
    }

    std::list<typename Iterator::value_type> const & operator*() const
    {
        return value_;
    }

    bool operator!=(NGramIterator const &that) const
    {
        return this->iter_ != that.iter_;
    }

private:
    Iterator iter_;
    Iterator end_;
    int n_;
    mutable std::list<typename Iterator::value_type> value_;
};

template <class Iterable>
class NGramIterable {
public:
    using const_iterator = NGramIterator<
        typename std::decay<Iterable>::type::const_iterator>;
    using value_type = typename const_iterator::value_type;

    NGramIterable(Iterable &&iterable, int n)
        : iterable_(iterable), n_(n)
    {}

    const_iterator begin() const
    {
        return const_iterator(iterable_.begin(), iterable_.end(), n_);
    }

    const_iterator end() const
    {
        return const_iterator(iterable_.end(), iterable_.end(), n_);
    }

private:
    Iterable iterable_;
    int n_;
};

template <class Iterable>
NGramIterable<Iterable> ngram(Iterable &&iterable, int n)
{
    return NGramIterable<Iterable>(std::forward<Iterable>(iterable), n);
}

}
@

@<test_ngram.cc@>=
#include "ebt.h"
#include <iostream>

int main()
{
    std::vector<std::string> words {"a", "b", "c"};

    for (auto &ngram: ebt::ngram(words, 2)) {
        std::cout << ngram << std::endl;
    }

    return 0;
}
@

\section{Parsers}

@<parser@>=
namespace ebt {

class ParserException
    : public std::exception {

public:
    ParserException(std::string msg);

    virtual char const * what() const noexcept;

private:
    std::string msg_;
};

std::string parse_string(std::istream &is);
std::istream & parse(std::istream &is, int &i);
std::istream & parse(std::istream &is, double &d);
void parse_whitespace(std::istream &is);
void expect(std::istream &is, char c);

}
@

@<parser impl@>=
namespace ebt {

ParserException::ParserException(std::string msg)
    : msg_(msg)
{}

char const * ParserException::what() const noexcept
{
    return msg_.c_str();
}

std::string parse_string(std::istream &is)
{
    std::string result;
    expect(is, '"');
    is.get();
    char c[2];
    c[1] = '\0';
    while (is.peek() != '"') {
        if (is.peek() == '\\') {
            is.get();
            if (is.peek() != '"' && is.peek() != '\\') {
                throw ParserException(
                    "can only escape \" and \\");
            }
        }
        c[0] = is.get();
        result.append(std::string(c));
    }
    is.get();
    return result;
}

std::istream & parse(std::istream &is, int &i)
{
    std::string s = "0123456789+-";
    std::string result;
    char c[2];
    c[1] = '\0';
    c[0] = is.peek();
    if (s.find(c) == std::string::npos) {
        throw ParserException("expecting double but found \""
            + std::string(c) + "\"");
    }
    while (s.find(c) != std::string::npos) {
        is.get();
        result.append(std::string(c));
        c[0] = is.peek();
    }
    i = std::stoi(result);
    return is;
}

std::istream & parse(std::istream &is, double &d)
{
    std::string s = "0123456789+-e.";
    std::string result;
    char c[2];
    c[1] = '\0';
    c[0] = is.peek();
    if (s.find(c) == std::string::npos) {
        throw ParserException("expecting double but found \""
            + std::string(c) + "\"");
    }
    while (s.find(c) != std::string::npos) {
        is.get();
        result.append(std::string(c));
        c[0] = is.peek();
    }
    d = std::stod(result);
    return is;
}

void parse_whitespace(std::istream &is)
{
    while (is.peek() == ' ' || is.peek() == '\n'
            || is.peek() == '\t') {
        is.get();
    }
}

void expect(std::istream &is, char c)
{
    char actual = is.peek();
    if (actual != c) {
        throw ParserException(std::string("expecting \"") + c
            + "\" but got \"" + actual + "\"");
    }
}

}
@

\section{Sparse Vector}

@<sparse vector@>=
namespace ebt {

class SparseVector {
public:
    using const_iterator
        = typename std::unordered_map<std::string, double>::const_iterator;
    using iterator
        = typename std::unordered_map<std::string, double>::iterator;

    SparseVector() = default;

    SparseVector(std::initializer_list<
        std::pair<std::string const, double>> list);

    explicit SparseVector(std::unordered_map<std::string, double> map);

    double& operator()(std::string const &key);
    double operator()(std::string const &key) const;

    SparseVector & operator+=(SparseVector const &that);
    SparseVector & operator-=(SparseVector const &that);
    SparseVector & operator*=(double scalar);
    SparseVector & operator/=(double scalar);

    const_iterator begin() const;
    const_iterator end() const;

    iterator begin();
    iterator end();

    int size() const;

    friend double dot(SparseVector const &a, SparseVector const &b);
    friend bool in(std::string const &key, SparseVector const &v);
    friend std::ostream & operator<<(std::ostream &os, SparseVector const &v);

private:
    std::unordered_map<std::string, double> map_;
};

double dot(SparseVector const &a, SparseVector const &b);
bool in(std::string const &key, SparseVector const &v);

class SparseVectorParser {
public:
    SparseVectorParser(std::istream &is);

    std::pair<std::string, double> parse_key_value();
    std::unordered_map<std::string, double> parse_unordered_map();

private:
    std::istream &is_;
};

std::istream & operator>>(std::istream &is, SparseVector &v);
std::ostream & operator<<(std::ostream &os, SparseVector const &v);

}
@

@<sparse vector impl@>=
namespace ebt {

SparseVector::SparseVector(std::initializer_list<
        std::pair<std::string const, double>> list)
    : map_(list)
{}

SparseVector::SparseVector(std::unordered_map<std::string, double> map)
    : map_(std::move(map))
{}

double& SparseVector::operator()(std::string const &key)
{
    return map_[key];
}

double SparseVector::operator()(std::string const &key) const
{
    if (in(key, map_)) {
        return map_.at(key);
    } else {
        return 0;
    }
}

SparseVector & SparseVector::operator+=(SparseVector const &that)
{
    for (auto &p: that.map_) {
        map_[p.first] += p.second;
        if (std::fabs(map_[p.first]) < 1e-300) {
            map_.erase(p.first);
        }
    }
    return *this;
}

SparseVector & SparseVector::operator-=(SparseVector const &that)
{
    for (auto &p: that.map_) {
        map_[p.first] -= p.second;
        if (std::fabs(map_[p.first]) < 1e-300) {
            map_.erase(p.first);
        }
    }
    return *this;
}

SparseVector & SparseVector::operator*=(double scalar)
{
    std::vector<std::string> to_erase;

    for (auto &p: map_) {
        p.second *= scalar;
        if (std::fabs(p.second) < 1e-300) {
            to_erase.push_back(p.first);
        }
    }

    for (auto &k: to_erase) {
        map_.erase(k);
    }
    return *this;
}

SparseVector & SparseVector::operator/=(double scalar)
{
    std::vector<std::string> to_erase;

    for (auto &p: map_) {
        p.second /= scalar;
        if (std::fabs(p.second) < 1e-300) {
            to_erase.push_back(p.first);
        }
    }

    for (auto &k: to_erase) {
        map_.erase(k);
    }
    return *this;
}

SparseVector::const_iterator SparseVector::begin() const
{
    return map_.begin();
}

SparseVector::const_iterator SparseVector::end() const
{
    return map_.end();
}

SparseVector::iterator SparseVector::begin()
{
    return map_.begin();
}

SparseVector::iterator SparseVector::end()
{
    return map_.end();
}

int SparseVector::size() const
{
    return map_.size();
}

double dot(SparseVector const &a, SparseVector const &b)
{
    if (b.map_.size() < a.map_.size()) {
        return dot(b, a);
    }

    double result = 0;
    for (auto &p: a) {
        result += p.second * b(p.first);
    }
    return result;
}

bool in(std::string const &key, SparseVector const &v)
{
    return in(key, v.map_);
}

std::ostream & operator<<(std::ostream &os, SparseVector const &v)
{
    return os << "{" << ebt::join(ebt::map(v,
        [](std::pair<const std::string, double> const &p) {
            return ebt::format("\"{}\": {}", escapeseq(p.first),
                p.second);
        }), ", ") << "}";
}

}

namespace ebt {

SparseVectorParser::SparseVectorParser(std::istream &is)
    : is_(is)
{}

std::pair<std::string, double>
SparseVectorParser::parse_key_value()
{
    std::string key = parse_string(is_);
    expect(is_, ':');
    is_.get();
    parse_whitespace(is_);
    double value;
    parse(is_, value);
    return std::make_pair(key, value);
}

std::unordered_map<std::string, double>
SparseVectorParser::parse_unordered_map()
{
    std::unordered_map<std::string, double> result;

    expect(is_, '{');
    is_.get();
    parse_whitespace(is_);
    while (is_.peek() != '}') {
        std::pair<std::string, double> p = parse_key_value();
        result[p.first] = p.second;
        if (is_.peek() == ',') {
            is_.get();
        }
        parse_whitespace(is_);
    }
    is_.get();

    return result;
}

std::istream & operator>>(std::istream &is, SparseVector &v)
{
    v = SparseVector(SparseVectorParser(is).parse_unordered_map());
    return is;
}

}
@

@<test_sparse_vector.cc@>=
#include <iostream>
#include <sstream>
#include "ebt.h"

void test1()
{
    ebt::SparseVector v {{"a", 1}, {"b", 2}};

    v *= 3;

    for (auto &p: v) {
        std::cout << p << std::endl;
    }
}

void test2()
{
    std::istringstream iss("{}");

    ebt::SparseVector v;

    iss >> v;

    for (auto &p: v) {
        std::cout << p << std::endl;
    }
}

void test3()
{
    std::istringstream iss("{\"a\": 1, \"b\": 2}");

    ebt::SparseVector v;

    iss >> v;

    for (auto &p: v) {
        std::cout << p << std::endl;
    }
}

int main()
{
    test1();
    test2();
    test3();

    return 0;
}
@

\section{Timer}

@<timer@>=
namespace ebt {

struct Timer {
    time_t before;
    time_t after;

    Timer();

    ~Timer();
};

}
@

@<timer impl@>=
namespace ebt {

Timer::Timer()
{
    std::time(&before);
}

Timer::~Timer()
{
    std::time(&after);
    int seconds = int(std::difftime(after, before));

    std::cout << seconds / 60 << " mins " << seconds % 60 << " secs"
        << std::endl;
}

}
@

\section{Argument Parser}

@<argument parser@>=
namespace ebt {

struct Arg {
    std::string name;
    std::string help_str;
    bool required;
};

struct ArgumentSpec {
    std::string name;
    std::string description;
    std::vector<Arg> keys;
};

void usage(ArgumentSpec spec);

std::unordered_map<std::string, std::string>
parse_args(int argc, char *argv[], ArgumentSpec spec);

}
@

@<argument parser impl@>=
namespace ebt {

void usage(ArgumentSpec spec)
{
    std::cout << "usage: " << spec.name << " args..." << std::endl;
    std::cout << std::endl;
    std::cout << spec.description << std::endl;
    std::cout << std::endl;
    std::cout << "Arguments:" << std::endl;
    std::cout << std::endl;

    for (auto &i: spec.keys) {
        std::cout << "    --" << i.name;
        for (int k = 0; k < 24 - int(i.name.size()); ++k) {
            std::cout << " ";
        }
        std::cout << i.help_str << std::endl;
    }

    std::cout << std::endl;
}

std::unordered_map<std::string, std::string>
parse_args(int argc, char *argv[], ArgumentSpec spec)
{
    std::unordered_set<std::string> required;
    std::unordered_set<std::string> keys;

    for (auto &i: spec.keys) {
        if (i.required) {
            required.insert(i.name);
        }
        keys.insert(i.name);
    }

    std::unordered_map<std::string, std::string> result;
    int i = 1;
    while (i < argc) {
        if (ebt::startswith(argv[i], "--")) {
            std::string key = std::string(argv[i]).substr(2);
            if (!ebt::in(key, keys)) {
                std::cout << "unknown argument --" << key << std::endl;
                exit(1);
            }
            if (i + 1 < argc && !ebt::startswith(argv[i + 1], "--")) {
                std::string value = std::string(argv[i + 1]);
                result[key] = value;
                ++i;
            } else {
                result[key] = "";
            }
        } else {
            std::cout << "unknown argument " << argv[i] << std::endl;
            exit(1);
        }
        ++i;
    }

    for (auto &i: required) {
        if (!ebt::in(i, result)) {
            std::cout << "argument --" << i << " is required" << std::endl;
            exit(1);
        }
    }

    return result;
}

}
@

\end{document}
