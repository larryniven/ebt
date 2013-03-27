\documentclass{article}
\usepackage{fullpage}
\usepackage{tikz}
\usepackage{amsmath, amsfonts}

\title{Finite State Transducer}
\author{Hao Tang\\\texttt{haotang@ttic.edu}}
\begin{document}

\maketitle

\section{Semiring}

A semiring is defined as a five tuple
$(\mathbb{K}, \oplus, \otimes, \overline{0}, \overline{1})$
in which
\begin{enumerate}
\item $(\mathbb{K}, \oplus, \overline{0})$ forms a commutative
    monoid with identity $\overline{0}$.
\item $(\mathbb{K}, \otimes, \overline{1})$ forms a monoid
    with identity $\overline{1}$.
\item $\otimes$ distributes over $\oplus$
\item $\overline{0}$ is the annihilator of $\otimes$.
\end{enumerate}
One example is the tropical semiring $(\mathbb{R}_+ \cup \{\infty\},
\min, +, \infty, 0)$.

@<tropical semiring@>=
class TropicalSemiring {
public:
    typename double Element;

    double add(double x, double, y);
    double mul(double x, double y);
};
@

@<tropical semiring impl@>=
double TropicalSemiring::add(double x, double y)
{
    return std::min(x, y);
}

double TropicalSemiring::mul(double x, double y)
{
    return x + y;
}
@

\section{Graph}

A graph $G$ is a pair $(V, E)$ where $E \subseteq V \times V$.
Let $\text{adj}(u) = \{(u, v) \in E \mid v \in V\}$.

@<graph data@>=
struct GraphData {
    ebt::Range vertices;
    ebt::Range edges;
    std::vector<int> tail;
    std::vector<int> head;
    std::vector<double> weight;
};
@

@<graph@>=
class Graph {
public:
    Graph(GraphData const &g);
    Graph(GraphData &&g);

    ebt::Range vertices() const;
    ebt::Range edges() const;
    int tail(int e) const;
    int head(int e) const;
    double weight(int e) const;
    std::vector<int> const & adj(int v) const;

private:
    void index_adj();

    GraphData g_;
    std::vector<std::vector<int>> adj_;
};
@

@<graph impl@>=
Graph::Graph(GraphData const &g)
    : g_(g)
{
    index_adj();
}

Graph::Graph(GraphData &&g)
    : g_(std::move(g))
{
    index_adj();
}

ebt::Range Graph::vertices() const
{
    return g_.vertices;
}

ebt::Range Graph::edges() const
{
    return g_.edges;
}

int Graph::tail(int e) const
{
    return g_.tail.at(e);
}

int Graph::head(int e) const
{
    return g_.head.at(e);
}

double Graph::weight(int e) const
{
    return g_.weight.at(e);
}

void Graph::index_adj()
{
    for (auto &&i: edges()) {
        adj_[tail(i)].push_back(head(i));
    }
}

std::vector<int> const & Graph::adj(int v) const
{
    return adj_.at(v);
}
@

\section{Depth First Search}

@<depth first search@>=
template <class Traversing, class Traversed>
void depth_first_search(Graph const &g, int root,
    Traversing traversing, Traversed traversed)
{
    
}
@

\section{Topological Search}

\section{Shortest Path}

@<Bellman-Ford@>=
class BellmanFord {
public:
    BellmanFord(Graph const &g, int s);
    void compute();
    double distance(int t) const;
    bool tense(int e);
    void relax(int e);

private:
    Graph const &g_;
    std::vector<double> d_;
    std::vector<int> pi_;
};
@

@<Bellman-Ford impl@>=
BellmanFord::BellmanFord(Graph const &g, int s)
    : g_(g), d_(g_.vertices().size()), pi_(g_.vertices().size())
{
    std::fill(d_.begin(), d_.end(),
        std::numeric_limits<double>::infinity());

    d_[s] = 0;
}

void BellmanFord::compute()
{
    for (auto &&i: g_.vertices()) {
        for (auto &&e: g_.edges()) {
            if (tense(e)) {
                relax(e);
            }
        }
    }
}

double BellmanFord::distance(int t) const
{
    return d_.at(t);
}

bool BellmanFord::tense(int e)
{
    auto &&u = g_.tail(e);
    auto &&v = g_.head(e);

    return d_.at(u) + g_.weight(e) > d_.at(v);
}

void BellmanFord::relax(int e)
{
    auto &&u = g_.tail(e);
    auto &&v = g_.head(e);

    d_[v] = d_.at(u) + g_.weight(e);
    pi_[v] = e;
}
@

\section{Wrap-up}

@<fst.h@>=
#ifndef FST_H
#define FST_H

#include "ebt.h"
#include <vector>

@<graph data@>
@<graph@>
@<Bellman-Ford@>

#endif
@

@<fst.cc@>=
#include "fst.h"
#include <limits>
#include <algorithm>

@<graph impl@>
@<Bellman-Ford impl@>
@

\end{document}
