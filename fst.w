\documentclass{article}
\usepackage{tikz}
\usepackage{amsmath, amsfonts}
\usepackage{amsthm}
\usepackage{algorithmic}

\newtheorem{lemma}{Lemma}
\newtheorem{corollary}{Corollary}
\newtheorem{theorem}{Theorem}

\title{Finite State Transducers}
\author{Hao Tang\\\texttt{haotang@ttic.edu}}
\begin{document}

\maketitle

\section{Graph}

\subsection{Plain Graph}

A graph $G$ is a pair $(V, E)$ where $E \subseteq V \times V$.
Let $\text{adj}(u) = \{(u, v) \in E \mid v \in V\}$.

@<graph data@>=
template <class V, class E>
struct GraphData {
    std::unordered_set<V> vertices;
    std::unordered_set<E> edges;
    std::unordered_map<E, V> tail;
    std::unordered_map<E, V> head;
};
@

@<graph@>=
template <class V, class E, class Data=GraphData<V, E>>
class Graph {
public:
    Graph(Data g)
        : g_(std::move(g))
    {
        index_adj();
    }

    std::unordered_set<V> const & vertices() const
    {
        return g_.vertices;
    }

    std::unordered_set<E> const & edges() const
    {
        return g_.edges;
    }

    V const & tail(E const &e) const
    {
        return g_.tail.at(e);
    }

    V const & head(E const &e) const
    {
        return g_.head.at(e);
    }

    std::unordered_set<E> const & adj(V const &v) const
    {
        if (adj_.find(v) == adj_.end()) {
            return empty_;
        } else {
            return adj_.at(v);
        }
    }

protected:
    void index_adj()
    {
        for (auto &e: edges()) {
            adj_[tail(e)].insert(e);
        }
    }

    Data g_;
    std::unordered_map<V, std::unordered_set<E>> adj_;
    std::unordered_set<E> empty_;
};
@

The following is a type of graph specialized with integer vertices and
integer edges.

@<range graph data@>=
struct RangeGraphData {
    ebt::Range vertices;
    ebt::Range edges;
    std::vector<int> tail;
    std::vector<int> head;
};
@

@<range graph@>=
class RangeGraph {
public:
    RangeGraph(RangeGraphData g);

    ebt::Range vertices() const;
    ebt::Range edges() const;
    int tail(int e) const;
    int head(int e) const;
    std::unordered_set<int> const & adj(int v) const;

private:
    void index_adj();

    RangeGraphData g_;
    std::vector<std::unordered_set<int>> adj_;
};
@

@<range graph impl@>=
RangeGraph::RangeGraph(RangeGraphData g)
    : g_(std::move(g))
{
    index_adj();
}

ebt::Range RangeGraph::vertices() const
{
    return g_.vertices;
}

ebt::Range RangeGraph::edges() const
{
    return g_.edges;
}

int RangeGraph::tail(int e) const
{
    return g_.tail.at(e);
}

int RangeGraph::head(int e) const
{
    return g_.head.at(e);
}

void RangeGraph::index_adj()
{
    adj_.resize(vertices().size());
    for (auto &&i: edges()) {
        adj_[tail(i)].insert(i);
    }
}

std::unordered_set<int> const & RangeGraph::adj(int v) const
{
    return adj_.at(v);
}
@

\subsection{Weighted Graph}

A weighted graph is a graph with an additional weight
function $w: E \to \mathbb{R}$.

@<weighted graph data@>=
template <class V, class E>
struct WeightedGraphData {
    std::unordered_set<V> vertices;
    std::unordered_set<E> edges;
    std::unordered_map<E, V> tail;
    std::unordered_map<E, V> head;
    std::unordered_map<E, double> weights;
};
@

@<weighted graph@>=
template <class V, class E, class Data=WeightedGraphData<V, E>>
class WeightedGraph : public Graph<V, E, Data> {
public:
    WeightedGraph(Data g)
        : Graph<V, E, Data>(std::move(g))
    {}

    double weight(E const &e) const
    {
        return Graph<V, E, Data>::g_.weights.at(e);
    }
};
@

\section{Graph Algorithm}

\subsection{Depth First Search}

@<depth first search@>=
template <class V, class E>
void depth_first_search(Graph<V, E> const &g, V root,
    std::function<void(E)> begin_traverse,
    std::function<void(E)> end_traverse)
{
    std::stack<E> stack;
    std::vector<E> path;
    std::unordered_set<E> traversed;

    for (E const &e: g.adj(root)) {
        stack.push(e);
        traversed.insert(e);
    }

    while (stack.size() > 0) {
        E e = stack.top();
        stack.pop();
        while (path.size() > 0) {
            auto &&adj = g.adj(g.head(path.back()));
            if (adj.find(e) == adj.end()) {
                end_traverse(path.back());
                path.resize(path.size() - 1);
            } else {
                break;
            }
        }
        path.push_back(e);
        begin_traverse(e);
        traversed.insert(e);
        for (E const &ch: g.adj(g.head(e))) {
            if (traversed.find(ch) == traversed.end()) {
                stack.push(ch);
            }
        }
    }

    while (path.size() > 0) {
        end_traverse(path.back());
        path.resize(path.size() - 1);
    }
}
@

@<test_dfs.cc@>=
#include "ebt.h"
#include "fst.h"
#include <iostream>

int main()
{
    Graph<int, int> g(GraphData<int, int> {
        {0, 1, 2, 3, 4, 5},
        {0, 1, 2, 3, 4, 5},
        {{0, 0}, {1, 0}, {2, 1}, {3, 1}, {4, 2}, {5, 2}},
        {{0, 1}, {1, 2}, {2, 3}, {3, 4}, {4, 4}, {5, 5}}
    });

    auto b = [](int e) { std::cout << "b: " << e << std::endl; };
    auto e = [](int e) { std::cout << "e: " << e << std::endl; };

    depth_first_search<int, int>(g, 0, b, e);

    return 0;
}
@

\subsection{Shortest Path}

@<shortest path@>=
template <class V, class E>
std::pair<std::unordered_map<V, double>,
    std::unordered_map<V, E>>
shortest_path(WeightedGraph<V, E> const &g, V const &s)
{
    std::unordered_set<V> q {s};
    std::unordered_map<V, double> d;
    std::unordered_map<V, E> pi;

    d[s] = 0;

    auto d_get = [&](V const &v) {
        if (d.find(v) == d.end()) {
            return std::numeric_limits<double>::infinity();
        } else {
            return d.at(v);
        }
    };

    while (q.size() > 0) {
        V v = *(q.begin());
        std::cout << "v = " << v << std::endl;
        q.erase(v);
        for (auto &e: g.adj(v)) {
            std::cout << "check " << e << std::endl;
            if (d_get(g.head(e)) > d_get(v) + g.weight(e)) {
                std::cout << "relax " << g.head(e) << " to "
                    << d.at(v) << " + " << g.weight(e) << " = ";
                d[g.head(e)] = d.at(v) + g.weight(e);
                std::cout << d.at(g.head(e)) << std::endl;
                q.insert(g.head(e));
            }
        }
    }

    return std::make_pair(d, pi);
}
@

@<test_shortest.cc@>=
#include "ebt.h"
#include "fst.h"
#include <iostream>
#include <utility>

int main()
{
    WeightedGraph<int, int> g(WeightedGraphData<int, int> {
        {0, 1, 2, 3},
        {0, 1, 2, 3, 4},
        {{0, 0}, {1, 1}, {2, 0}, {3, 0}, {4, 2}},
        {{0, 1}, {1, 2}, {2, 2}, {3, 3}, {4, 3}},
        {{0, 1}, {1, 1}, {2, 3}, {3, 2}, {4, 1}}
    });

    std::unordered_map<int, double> d;
    std::unordered_map<int, int> pi;

    std::tie(d, pi) = shortest_path(g, 0);

    for (auto &v: g.vertices()) {
        std::cout << "d[" << v << "]=" << d.at(v) << std::endl;
    }

    return 0;
}
@

\section{Wrap-up}

@<fst.h@>=
#ifndef FST_H
#define FST_H

#include "ebt.h"
#include <vector>
#include <functional>
#include <stack>
#include <unordered_set>
#include <unordered_map>
#include <iostream>
#include <algorithm>

@<range graph data@>
@<range graph@>
@<graph data@>
@<graph@>
@<depth first search@>
@<weighted graph data@>
@<weighted graph@>
@<shortest path@>

#endif
@

@<fst.cc@>=
#include "fst.h"

@<range graph impl@>
@

\appendix

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

\section{Shortest Distance}

\begin{algorithmic}[1]
\STATE $S = \{s\}$
\WHILE{$S \ne \emptyset$}
    \STATE $q \gets \text{pop}(S)$
    \STATE $R' \gets R(q)$
    \STATE $R(q) \gets \emptyset$
    \STATE $r' \gets r[q]$
    \STATE $r[q] \gets \overline{0}$
    \FOR{$e \in E[q]$}
        \STATE $D(n[e]) \gets D(n[e]) \cup R'e$ \label{alg:update-D}
        \IF{$d[n[e]] \ne d[n[e]] \oplus r' \otimes w[e]$} \label{alg:min}
            \STATE $R(n[e]) \gets R(n[e]) \cup R'e$
            \STATE $d[n[e]] \gets d[n[e]] \oplus r' \otimes w[e]$
            \STATE $r[n[e]] \gets r[n[e]] \oplus r' \otimes w[e]$
            \IF{$n[e] \notin S$}
                \STATE $\text{push}(n[e], S)$
            \ENDIF
        \ENDIF \label{alg:add-to-D}
    \ENDFOR
\ENDWHILE
\end{algorithmic}

\begin{lemma}
At line~\ref{alg:update-D}, $D(n[e]) \cap R'e = \emptyset$.
In other words, for every $\pi \in D(n[e])$, $\pi$ is added to
$D(n[e])$ once.
\end{lemma}

\begin{lemma}
\begin{align}
d[v] & = \bigoplus_{\pi \in D(v)} w[\pi] \\
r[v] & = \bigoplus_{\pi \in R(v)} w[\pi]
\end{align}
\end{lemma}

\begin{proof}
The proof is by induction on the number of elements popped from $S$.
Let $d'$ and $D'$ be the new $d$ and $D$ at line~\ref{alg:add-to-D}
within each loop.
No matter the condition at line~\ref{alg:min} passes or not,
we have
\begin{align}
d'[n[e]]
    & = d[n[e]] \oplus r' \otimes w[e] \\
    & = \bigoplus_{\pi \in D(n[e])} w[\pi] \oplus
        \bigoplus_{\pi' \in R'} w[\pi'] \otimes w[e] \\
    & = \bigoplus_{\pi \in D(n[e]) \cup R'e} w[\pi] \\
    & = \bigoplus_{\pi \in D'(n[e])} w[\pi].
\end{align}
\end{proof}

\begin{lemma}
If at time $t$ we have $d_t[n[e]] = d_t[n[e]] \oplus w[\pi] \oplus x$
for some $x \in \mathbb{K}$, then for any $t' > t$ we also have
$d_{t'}[n[e]] = d_{t'}[n[e]] \oplus w[\pi] \oplus x$
\end{lemma}

\begin{proof}
\begin{align}
d_{t'}[n[e]]
    & = d_t[n[e]] \oplus y \\
    & = d_t[n[e]] \oplus w[\pi] \oplus x_t \oplus y \\
    & = d_{t'}[n[e]] \oplus w[\pi] \oplus x_t 
\end{align}
\end{proof}

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

\end{document}
