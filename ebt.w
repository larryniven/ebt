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

}
@

\end{document}
