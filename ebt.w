\documentclass{article}
\usepackage{fullpage}

\title{ebt}
\author{Hao Tang\\\texttt{haotang@ttic.edu}}

\begin{document}

\maketitle

@<ebt.h@>=
#ifndef EBT_H
#define EBT_H

#include <vector>
#include <string>
#include <iterator>
#include <unordered_map>

namespace ebt {

std::vector<std::string> split(std::string const &s,
    std::string sep="");

class RangeIterator : public std::iterator<int, std::input_iterator_tag> {
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
    Range(int start, int end, int inc=1);

    RangeIterator begin() const;
    RangeIterator end() const;

    unsigned int size() const;

private:
    int start_;
    int end_;
    int inc_;
};

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

    R const & right() const
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

bool startswith(std::string const &s, std::string const &prefix);

size_t & hash_combine(size_t &seed, size_t value);

}

namespace std {

template <class Left, class Right>
struct hash<ebt::Either<Left, Right>> {
    size_t operator()(ebt::Either<Left, Right> const &e) const
    {
        if (e.is_left()) {
            return hash<Left>()(e.left());
        } else {
            return hash<Right>()(e.right());
        }
    }
};

template <class U, class V>
struct hash<pair<U, V>> {
    size_t operator()(std::pair<U, V> const &p) const
    {
        hash<U> v_hasher;
        hash<V> u_hasher;
        size_t seed = 0;
        ebt::hash_combine(seed, v_hasher(p.first));
        ebt::hash_combine(seed, u_hasher(p.second));
        return seed;
    }
};

template <class T1, class T2, class T3>
struct hash<tuple<T1, T2, T3>> {
    size_t operator()(tuple<T1, T2, T3> const &t) const
    {
        hash<T1> t1_hasher;
        hash<T2> t2_hasher;
        hash<T3> t3_hasher;

        size_t seed = 0;
        ebt::hash_combine(seed, t1_hasher(get<0>(t)));
        ebt::hash_combine(seed, t2_hasher(get<1>(t)));
        ebt::hash_combine(seed, t3_hasher(get<2>(t)));
        return seed;
    }
};

template <class U, class V>
ostream & operator<<(ostream &os, pair<U, V> const &p)
{
    os << "(" << p.first << ", " << p.second << ")";
    return os;
}

template <class T1, class T2, class T3>
ostream & operator<<(ostream &os, tuple<T1, T2, T3> const &t)
{
    os << "(" << get<0>(t) << ", " << get<1>(t) << ", "
        << get<2>(t) << ")";
    return os;
}

}

#endif
@

@<ebt.cc@>=
#include "ebt.h"
#include <algorithm>

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

bool startswith(std::string const &s, std::string const &prefix)
{
    return s.find(prefix) == 0;
}

size_t & hash_combine(size_t &seed, size_t value)
{
    seed ^= value + 0x9e3779b9
        + (seed >> 6) + (seed << 2);
    return seed;
}

}
@

\end{document}
