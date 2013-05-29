\documentclass{article}
\usepackage{fullpage}

\title{ebt}
\author{Hao Tang\\\texttt{haotang@ttic.edu}}

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

@<hash combine@>

@<uni ref@>
@<either@>
@<option@>

@<split@>
@<startswith@>

@<range@>
@<product@>
@<map@>
@<filter@>
@<chain@>

@<pair utility@>
@<tuple utility@>
@<unordered_map utility@>

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

@<split impl@>
@<range impl@>

@

\section{String}

@<startswith@>=
namespace ebt {

inline bool startswith(std::string const &s, std::string const &prefix)
{
    return s.find(prefix) == 0;
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
class UniRef {
public:
    UniRef() = default;

    UniRef(T &&value)
        : value_(new T(std::move(value)))
    {}

    T const & get() const
    {
        return *value_;
    }

    bool operator==(UniRef const &that) const
    {
        return value_ == that.value_;
    }

private:
    std::shared_ptr<T> value_;
};

template <class T>
class UniRef<T const &> {
public:
    UniRef()
        : value_(nullptr)
    {}

    UniRef(T const &value)
        : value_(&value)
    {}

    T const & get() const
    {
        return *value_;
    }

    bool operator==(UniRef const &that) const
    {
        return value_ == that.value_;
    }

private:
    T const *value_;
};

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
    size_t operator()(ebt::UniRef<T> const &that) const
    {
        hash<typename std::decay<T>::type const *> hasher;
        return hasher(&(that.get()));
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

template <class T1, class T2, class T3>
struct hash<tuple<T1, T2, T3>> {
    size_t operator()(tuple<T1, T2, T3> const &t) const noexcept
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

template <class T1, class T2, class T3>
ostream & operator<<(ostream &os, tuple<T1, T2, T3> const &t)
{
    os << "(" << get<0>(t) << ", " << get<1>(t) << ", "
        << get<2>(t) << ")";
    return os;
}

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

\subsection{Unordered Map}

@<unordered_map utility@>=
namespace ebt {

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

    typename ProductIterator::value_type operator*()
    {
        return typename ProductIterator::value_type(
            *outer_iter_, *inner_iter_);
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
public:
    MapIterator() = default;

    MapIterator(Iterator iter, Function const &f)
        : iter_(std::move(iter)), f_(&f)
    {}

    auto operator*() ->
        decltype(std::declval<Function>()(*std::declval<Iterator>()))
    {
        return (*f_)(*iter_);
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

private:
    Iterator iter_;
    Function const *f_;
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

    auto operator*() -> decltype(*std::declval<Iterator>())
    {
        return *iter_;
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

private:
    Iterator iter_;
    Iterator end_;
    Predicate const *p_;
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

    using SmartInner = UniRef<decltype(
        *std::declval<typename Outer::const_iterator>())>;

    Outer const *outer_iterable_;
    SmartInner inner_iterable_;
    typename Outer::const_iterator outer_iter_;
    typename Inner::const_iterator inner_iter_;

public:
    ChainIterator() = default;

    ChainIterator(Outer const &outer_iterable,
        typename Outer::const_iterator outer_iter)
        : outer_iterable_(&outer_iterable)
        , outer_iter_(std::move(outer_iter))
    {
        while (outer_iter_ != outer_iterable_->end()) {
            inner_iterable_ = SmartInner(*outer_iter_);
            inner_iter_ = inner_iterable_.get().begin();
            if (inner_iter_ != inner_iterable_.get().end()) {
                break;
            }
            ++outer_iter_;
        }
    }

    decltype(*std::declval<typename Inner::const_iterator>()) operator*()
    {
        return *inner_iter_;
    }

    ChainIterator & operator++()
    {
        ++inner_iter_;
        if (inner_iter_ == inner_iterable_.get().end()) {
            ++outer_iter_;
            while (outer_iter_ != outer_iterable_->end()) {
                inner_iterable_ = SmartInner(*outer_iter_);
                inner_iter_ = inner_iterable_.get().begin();
                if (inner_iter_ != inner_iterable_.get().end()) {
                    break;
                }
                ++outer_iter_;
            }
        }
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

}
@

@<test_chain.cc@>=
#include <iostream>
#include <vector>
#include <string>
#include "ebt.h"

void test1()
{
    std::vector<std::vector<std::string>> a {{"a", "aa"}, {"b", "bb"}, {"c", "cc"}};

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

int main()
{
    test1();
    test2();
    test3();

    return 0;
}
@

\end{document}
