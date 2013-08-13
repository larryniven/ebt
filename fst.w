\documentclass{article}
\usepackage{tikz}
\usepackage{amsmath, amsfonts}
\usepackage{amsthm}
\usepackage{algorithmic}

\newtheorem{lemma}{Lemma}
\newtheorem{corollary}{Corollary}
\newtheorem{theorem}{Theorem}

\title{Finite State Transducers}
\author{Hao Tang\\\texttt{haotang@@ttic.edu}}
\begin{document}

\maketitle

\tableofcontents

\section{Finite State Transducer (FST)}

\subsection{Graph}

A graph $G$ is a four tuple $(V, E, tail, head)$, where
$V$ is the vertex set, $E$ is the edge set, $tail: E \to V$
is a function that maps an edge to its tail vertex,
and $head: E \to V$ is a function that maps an edge
to its head vertex.  Representing a graph this way
instead of defining $E$ as a subset of $V \times V$
allow us to represent simple graphs and multigraphs
in a consistent way.  We will encounter multigraphs
when we define finite finite state transducers.

@<graph data@>=
template <class V, class E>
struct GraphData {
    std::unordered_set<V> vertices;
    std::unordered_set<E> edges;
    std::unordered_map<E, V> tail;
    std::unordered_map<E, V> head;
};
@

We wrap a set of commonly used functions in a class
for convenience.  This class also creates an adjacency
list upon receiving the graph data, and hence implements
the function $adj(u) = \{e \in E \mid tail(e) = u\}$.

@<graph@>=
template <class V, class E, class Data=GraphData<V, E>>
class Graph {
public:
    typedef V Vertex;
    typedef E Edge;

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

    Data & data()
    {
        return g_;
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
    std::unordered_map<E, double> weight;
};
@

@<weighted graph@>=
template <class V, class E, class Data=WeightedGraphData<V, E>>
class WeightedGraph : public Graph<V, E, Data> {
public:
    typedef typename Graph<V, E, Data>::Vertex Vertex;
    typedef typename Graph<V, E, Data>::Edge Edge;

    WeightedGraph(Data g)
        : Graph<V, E, Data>(std::move(g))
    {}

    double weight(E const &e) const
    {
        return Graph<V, E, Data>::g_.weight.at(e);
    }
};
@

\subsection{Finite State Transducer}

Let $\Sigma$ be a set of symbols or alphabet.
A finite state transducer (FST) is a weighted graph with
two additional functions $input: E \to \Sigma^*$ and
$output: E \to \Sigma^*$, a starting vertex, and an ending
vertex.

@<fst data@>=
template <class V, class E>
struct FstData {
    std::unordered_set<V> vertices;
    std::unordered_set<E> edges;
    std::unordered_map<E, V> tail;
    std::unordered_map<E, V> head;
    std::unordered_map<E, double> weight;
    std::unordered_map<E, std::string> input;
    std::unordered_map<E, std::string> output;
    V start;
    V end;
};
@

@<fst@>=
template <class V, class E, class Data=FstData<V, E>>
class Fst : public WeightedGraph<V, E, Data> {
public:
    typedef typename WeightedGraph<V, E, Data>::Vertex Vertex;
    typedef typename WeightedGraph<V, E, Data>::Edge Edge;

    Fst(Data g)
        : WeightedGraph<V, E, Data>(std::move(g))
    {}

    std::string const & input(E const &e) const
    {
        return WeightedGraph<V, E, Data>::g_.input.at(e);
    }

    std::string const & output(E const &e) const
    {
        return WeightedGraph<V, E, Data>::g_.output.at(e);
    }

    V const & start() const
    {
        return WeightedGraph<V, E, Data>::g_.start;
    }

    V const & end() const
    {
        return WeightedGraph<V, E, Data>::g_.end;
    }
};
@

\section{FST Algorithms}

\subsection{Depth First Search}

@<depth first search@>=
template <class G, class Begin, class End>
void depth_first_search(G const &g, typename G::Vertex root,
    Begin begin_traverse, End end_traverse)
{
    typedef typename G::Vertex V;
    typedef typename G::Edge E;

    std::stack<E> stack;
    std::vector<E> path;
    std::unordered_set<E> traversed;

    for (auto &&e: g.adj(root)) {
        stack.push(e);
        traversed.insert(e);
    }

    while (stack.size() > 0) {
        E e = stack.top();
        stack.pop();
        while (path.size() > 0 && g.head(path.back()) != g.tail(e)) {
            end_traverse(path.back());
            path.resize(path.size() - 1);
        }
        path.push_back(e);
        begin_traverse(e);
        traversed.insert(e);
        for (auto &&ch: g.adj(g.head(e))) {
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

    depth_first_search(g, 0, b, e);

    return 0;
}
@

\subsection{Shortest Path}

@<shortest path@>=
template <class T>
struct Unit {
    void operator()(T const &t) const
    {}
};

template <class G, class EventPop, class EventAdj, class EventUpdate>
std::pair<std::unordered_map<typename G::Vertex, double>,
    std::unordered_map<typename G::Vertex, typename G::Edge>>
shortest_path(G const &g, typename G::Vertex const &s,
    EventPop event_pop, EventAdj event_adj,
    EventUpdate event_update)
{
    typedef typename G::Vertex V;
    typedef typename G::Edge E;

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
        q.erase(v);

        event_pop(v);

        for (auto &&e: g.adj(v)) {

            event_adj(e);

            if (d_get(g.head(e)) > d_get(v) + g.weight(e)) {
                d[g.head(e)] = d.at(v) + g.weight(e);
                pi[g.head(e)] = e;
                q.insert(g.head(e));

                event_update(e);
            }
        }
    }

    return std::make_pair(d, pi);
}

template <class G>
std::pair<std::unordered_map<typename G::Vertex, double>,
    std::unordered_map<typename G::Vertex, typename G::Edge>>
shortest_path(G const &g, typename G::Vertex const &s)
{
    return shortest_path(g, s, Unit<typename G::Vertex>(),
        Unit<typename G::Edge>(), Unit<typename G::Edge>());
}
@

@<backtrack shortest path@>=
template <class G>
std::list<typename G::Edge> backtrack(
    G const &g,
    typename G::Vertex const &t,
    std::unordered_map<typename G::Vertex,
        typename G::Edge> const &pi)
{
    std::list<typename G::Edge> result;
    auto n = t;
    auto o = ebt::get(pi, n);
    while (o.has_some()) {
        result.push_front(o.some());
        n = g.tail(o.some());
        o = ebt::get(pi, n);
    }
    return result;
}
@

@<test_shortest.cc@>=
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

\subsection{Canonicalization}

@<canonicalize@>=
template <class F>
Fst<int, int> canonicalize(F const &fst)
{
    typedef typename F::Vertex V;
    typedef typename F::Edge E;

    std::unordered_map<V, int> vmap;
    std::unordered_map<E, int> emap;

    FstData<int, int> fst_data;

    auto b = [&](E const &e) {
        if (emap.find(e) == emap.end()) {
            emap[e] = emap.size();
            fst_data.edges.insert(emap.at(e));
        }
        if (vmap.find(fst.tail(e)) == vmap.end()) {
            vmap[fst.tail(e)] = vmap.size();
            fst_data.vertices.insert(vmap.at(fst.tail(e)));
        }
        if (vmap.find(fst.head(e)) == vmap.end()) {
            vmap[fst.head(e)] = vmap.size();
            fst_data.vertices.insert(vmap.at(fst.head(e)));
        }
        fst_data.tail[emap.at(e)] = vmap.at(fst.tail(e));
        fst_data.head[emap.at(e)] = vmap.at(fst.head(e));
        fst_data.weight[emap.at(e)] = fst.weight(e);
        fst_data.input[emap.at(e)] = fst.input(e);
        fst_data.output[emap.at(e)] = fst.output(e);
    };
    auto e = [&](E const &e) {};
    depth_first_search(fst, fst.start(), b, e);

    fst_data.start = vmap.at(fst.start());
    fst_data.end = vmap.at(fst.end());

    return Fst<int, int>(std::move(fst_data));
}
@

\subsection{Composition}

@<self-loop fst@>=
template <class Fst>
class SelfLoopFst {
public:
    typedef typename Fst::Vertex Vertex;
    typedef ebt::Either<typename Fst::Edge, int> Edge;

    typedef Vertex V;
    typedef Edge E;

private:
    Fst fst_;
    std::unordered_map<int, V> loop_end_points_;
    std::unordered_map<V, int> loops_;
    std::string epsilon_;

public:
    SelfLoopFst(Fst fst)
        : fst_(std::move(fst))
        , epsilon_("<eps>")
    {
        int i = 0;
        for (auto &v: fst_.vertices()) {
            loops_[v] = i;
            loop_end_points_[i] = v;
            ++i;
        }
    }

    auto vertices() const -> decltype(this->fst_.vertices())
    {
        return fst_.vertices();
    }

    std::unordered_set<E> edges() const
    {
        std::unordered_set<E> result;
        for (auto &e: fst_.edges()) {
            result.insert(E(ebt::left(e)));
        }
        for (auto &pair: loop_end_points_) {
            result.insert(E(ebt::right(pair.first)));
        }
        return result;
    }

    V const & tail(E const &e) const
    {
        if (e.is_right()) {
            return loop_end_points_.at(e.right());
        } else {
            return fst_.tail(e.left());
        }
    }

    V const & head(E const &e) const
    {
        if (e.is_right()) {
            return loop_end_points_.at(e.right());
        } else {
            return fst_.head(e.left());
        }
    }

    struct Adj {
        using iterable = decltype(
            std::declval<Fst>().adj(std::declval<V>()));

        using return_type
            = ebt::ChainIterable2<std::vector<E>,
                ebt::MapIterable<iterable,
                    std::function<E(typename Fst::Edge)>>>;
    };

    typename Adj::return_type adj(V const &v) const
    {
        std::function<E(typename Fst::Edge)> f
            = [](typename Fst::Edge e)
                { return E(ebt::left(std::move(e))); };

        return ebt::chain(std::vector<E>
            { E(ebt::right(loops_.at(v))) },
            ebt::map(fst_.adj(v), std::move(f)));
    }

    double weight(E const &e) const
    {
        if (e.is_right()) {
            return 0;
        } else {
            return fst_.weight(e.left());
        }
    }

    std::string const & input(E const &e) const
    {
        if (e.is_right()) {
            return epsilon_;
        } else {
            return fst_.input(e.left());
        }
    }

    std::string const & output(E const &e) const
    {
        if (e.is_right()) {
            return epsilon_;
        } else {
            return fst_.output(e.left());
        }
    }

    V const & start() const
    {
        return fst_.start();
    }

    V const & end() const
    {
        return fst_.end();
    }
};

template <>
class SelfLoopFst<Fst<int, int, FstData<int, int>>>
    : public Fst<int, int, FstData<int, int>> {
public:
    typedef int Vertex;
    typedef int Edge;

    SelfLoopFst(Fst<int, int, FstData<int, int>> fst);
};
@

@<self-loop fst impl@>=
SelfLoopFst<Fst<int, int, FstData<int, int>>>::SelfLoopFst(
    Fst<int, int, FstData<int, int>> fst)
    : Fst<int, int, FstData<int, int>>(std::move(fst.data()))
{
    int max_e = 0;
    for (auto &e: g_.edges) {
        if (e > max_e) {
            max_e = e;
        }
    }

    for (auto &v: g_.vertices) {
        int e = ++max_e;
        g_.edges.insert(e);
        g_.tail[e] = v;
        g_.head[e] = v;
        g_.weight[e] = 0;
        g_.input[e] = "<eps>";
        g_.output[e] = "<eps>";
        adj_[v].insert(e);
    }
}
@

@<test_self_loop.cc@>=
#include "ebt.h"
#include "fst.h"

int main()
{
    Fst<int, int> fst(FstData<int, int> {
        {0, 1, 2},
        {0, 1},
        {{0, 0}, {1, 1}},
        {{0, 1}, {1, 2}},
        {{0, 0}, {1, 0}},
        {{0, ""}, {1, ""}},
        {{0, ""}, {1, ""}}
    });

    SelfLoopFst<Fst<int, int>> fst_loops(fst);

    auto b = [](ebt::Either<int, int> const &e) {
        if (e.is_left()) {
            std::cout << "begin l:" << e.left() << std::endl;
        } else {
            std::cout << "begin r:" << e.right() << std::endl;
        }
    };
    auto e = [](ebt::Either<int, int> const &e) {
        if (e.is_left()) {
            std::cout << "end l:" << e.left() << std::endl;
        } else {
            std::cout << "end r:" << e.right() << std::endl;
        }
    };

    depth_first_search(fst_loops, 0, b, e);

    return 0;
}
@

@<two-way product fst@>=
template <class Fst1, class Fst2>
class EpsilonFreeProductFst2 {
private:
    Fst1 fst1_;
    Fst2 fst2_;

public:
    typedef std::pair<typename Fst1::Vertex,
        typename Fst2::Vertex> Vertex;
    typedef Vertex V;

    struct Adj {
        using product_iterable
            = ebt::ProductIterable<
                decltype(std::declval<Fst1>().adj(
                    std::declval<V>().first)),
                decltype(std::declval<Fst2>().adj(
                    std::declval<V>().second))>;

        using product_value
            = typename product_iterable::value_type;

        using return_type
            = ebt::FilterIterable<product_iterable,
                std::function<bool(product_value const &)>>;
    };

    typedef typename Adj::product_value Edge;
    typedef Edge E;

    EpsilonFreeProductFst2(Fst1 fst1, Fst2 fst2)
        : fst1_(std::move(fst1)), fst2_(std::move(fst2))
    {}

    std::unordered_set<V> vertices() const
    {
        std::unordered_set<V> result { start() };
        auto b = [&](E const &e) {
            result.insert(head(e));
        };
        auto e = [](E const &e) {};
        depth_first_search(*this, start(), b, e);
        return result;
    }

    std::unordered_set<E> edges() const
    {
        std::unordered_set<E> result;
        auto b = [&](E const &e) {
            result.insert(e);
        };
        auto e = [](E const &e) {};
        depth_first_search(*this, start(), b, e);
        return result;
    }

    V tail(E const &e) const
    {
        return std::make_pair(fst1_.tail(e.first.get()),
            fst2_.tail(e.second.get()));
    }

    V head(E const &e) const
    {
        return std::make_pair(fst1_.head(e.first.get()),
            fst2_.head(e.second.get()));
    }

    typename Adj::return_type adj(V const &v) const
    {
        std::function<
            bool(typename Adj::product_value const &)> f
            = [&](typename Adj::product_value const &p) {
                return fst1_.output(p.first.get())
                    == fst2_.input(p.second.get());
            };

        return ebt::filter(ebt::product(fst1_.adj(v.first),
            fst2_.adj(v.second)), std::move(f));
    }

    double weight(E const &e) const
    {
        return fst1_.weight(e.first.get())
            + fst2_.weight(e.second.get());
    }

    std::string input(E const &e) const
    {
        return fst1_.input(e.first.get());
    }

    std::string output(E const &e) const
    {
        return fst2_.output(e.second.get());
    }

    V start() const
    {
        return std::make_pair(fst1_.start(), fst2_.start());
    }

    V end() const
    {
        return std::make_pair(fst1_.end(), fst2_.end());
    }
};

template <class Fst1, class Fst2>
using ProductFst2 = EpsilonFreeProductFst2<SelfLoopFst<Fst1>,
    SelfLoopFst<Fst2>>;

template <class Fst1, class Fst2>
ProductFst2<Fst1, Fst2> compose(Fst1 fst1, Fst2 fst2)
{
    return ProductFst2<Fst1, Fst2>(std::move(fst1),
        std::move(fst2));
}

template <class Fst1, class Fst2>
EpsilonFreeProductFst2<Fst1, Fst2>
epsilon_free_compose(Fst1 fst1, Fst2 fst2)
{
    return EpsilonFreeProductFst2<Fst1, Fst2>(std::move(fst1),
        std::move(fst2));
}
@

@<test_fst_product2.cc@>=
#include "fst.h"
#include <iostream>

int main()
{
    Fst<int, int> fst1(FstData<int, int> {
        {0, 1, 2},
        {0, 1},
        {{0, 0}, {1, 1}},
        {{0, 1}, {1, 2}},
        {{0, 1}, {1, 1}},
        {{0, "a"}, {1, "b"}},
        {{0, "A"}, {1, "B"}},
        0,
        2
    });

    Fst<int, int> fst2(FstData<int, int> {
        {0},
        {0, 1, 2, 3},
        {{0, 0}, {1, 0}, {2, 0}, {3, 0}},
        {{0, 0}, {1, 0}, {2, 0}, {3, 0}},
        {{0, 3}, {1, 4}, {2, 5}, {3, 6}},
        {{0, "A"}, {1, "B"}, {2, "C"}, {3, "A"}},
        {{0, "1"}, {1, "2"}, {2, "3"}, {3, "4"}},
        0,
        0
    });

    auto fst = epsilon_free_compose(fst1, fst2);

    std::unordered_map<typename decltype(fst)::Vertex, double> d;
    std::unordered_map<typename decltype(fst)::Vertex,
        typename decltype(fst)::Edge> pi;

    std::tie(d, pi) = shortest_path(fst, fst.start());

    for (auto &p: d) {
        std::cout << "d[" << p.first.first << ", "
            << p.first.second << "]=" << p.second << std::endl;
    }

    std::cout << fst.vertices().size() << std::endl;
    std::cout << fst.edges().size() << std::endl;

    return 0;
}
@

@<three-way product fst@>=
template <class Fst1, class Fst2, class Fst3>
class EpsilonFreeProductFst3 {
public:
    typedef std::tuple<typename Fst1::Vertex,
        typename Fst2::Vertex,
        typename Fst3::Vertex> Vertex;
    typedef std::tuple<typename Fst1::Edge,
        typename Fst2::Edge,
        typename Fst3::Edge> Edge;

    typedef Vertex V;
    typedef Edge E;

    EpsilonFreeProductFst3(Fst1 fst1, Fst2 fst2, Fst3 fst3)
        : fst1_(std::move(fst1))
        , fst2_(std::move(fst2))
        , fst3_(std::move(fst3))
    {
        index_fst2();
    }

    std::unordered_set<V> vertices() const
    {
        std::unordered_set<V> result { start() };
        auto b = [&](E const &e) {
            result.insert(head(e));
        };
        auto e = [](E const &e) {};
        depth_first_search(*this, start(), b, e);
        return result;
    }

    std::unordered_set<E> edges() const
    {
        std::unordered_set<E> result;
        auto b = [&](E const &e) {
            result.insert(e);
        };
        auto e = [](E const &e) {};
        depth_first_search(*this, start(), b, e);
        return result;
    }

    V tail(E const &e) const
    {
        return std::make_tuple(fst1_.tail(std::get<0>(e)),
            fst2_.tail(std::get<1>(e)),
            fst3_.tail(std::get<2>(e)));
    }

    V head(E const &e) const
    {
        return std::make_tuple(fst1_.head(std::get<0>(e)),
            fst2_.head(std::get<1>(e)),
            fst3_.head(std::get<2>(e)));
    }

    struct Adj {
        using adj1 = decltype(std::declval<Fst1>().adj(
            std::get<0>(std::declval<V>())));
        using adj3 = decltype(std::declval<Fst3>().adj(
            std::get<2>(std::declval<V>())));
        using product = ebt::ProductIterable<adj1, adj3>;
        using product_value = typename product::value_type;
        using edge_iterable = ebt::MapIterable<
            std::unordered_set<typename Fst2::Edge> const &,
            std::function<E(typename Fst2::Edge)>>;
        using iterable_set = ebt::MapIterable<product,
            std::function<edge_iterable(product_value const &p)>>;
        using return_type = ebt::ChainIterable<iterable_set>;
    };

    typename Adj::return_type adj(V const &v) const
    {
        std::unordered_set<typename Fst2::Edge> empty;
        std::function<typename Adj::edge_iterable(
                typename Adj::product_value const &)> g
            = [&, empty](typename Adj::product_value const &p) {
                typename Fst1::Edge const &e1 = p.first.get();
                typename Fst3::Edge const &e3 = p.second.get();

                std::function<E(typename Fst2::Edge)> f
                    = [&](typename Fst2::Edge const &e2) {
                        return E(e1, e2, e3);
                    };
                return ebt::map(
                    ebt::get(fst2_index_,
                        std::make_tuple(std::get<1>(v),
                            fst1_.output(e1),
                            fst3_.input(e3)),
                        empty),
                    std::move(f));
            };
        return ebt::chain(ebt::map(
            ebt::product(fst1_.adj(std::get<0>(v)),
                fst3_.adj(std::get<2>(v))),
            std::move(g)));
    }

    double weight(E const &e) const
    {
        return fst1_.weight(std::get<0>(e))
            + fst2_.weight(std::get<1>(e))
            + fst3_.weight(std::get<2>(e));
    }

    std::string input(E const &e) const
    {
        return fst1_.input(std::get<0>(e));
    }

    std::string output(E const &e) const
    {
        return fst3_.output(std::get<2>(e));
    }

    V start() const
    {
        return std::make_tuple(fst1_.start(), fst2_.start(),
            fst3_.start());
    }

    V end() const
    {
        return std::make_tuple(fst1_.end(), fst2_.end(),
            fst3_.end());
    }

private:
    Fst1 fst1_;
    Fst2 fst2_;
    Fst3 fst3_;

    std::unordered_map<std::tuple<typename Fst2::Vertex,
        std::string, std::string>,
        std::unordered_set<typename Fst2::Edge>> fst2_index_;

    void index_fst2()
    {
        for (auto &v: fst2_.vertices()) {
            for (auto &e: fst2_.adj(v)) {
                fst2_index_[std::make_tuple(v, fst2_.input(e),
                    fst2_.output(e))].insert(e);
            }
        }
    }
};

template <class Fst1, class Fst2, class Fst3>
using ProductFst3 = EpsilonFreeProductFst3<SelfLoopFst<Fst1>,
    SelfLoopFst<Fst2>, SelfLoopFst<Fst3>>;

template <class Fst1, class Fst2, class Fst3>
ProductFst3<Fst1, Fst2, Fst3>
compose(Fst1 fst1, Fst2 fst2, Fst3 fst3)
{
    return ProductFst3<Fst1, Fst2, Fst3>(std::move(fst1),
        std::move(fst2), std::move(fst3));
}

template <class Fst1, class Fst2, class Fst3>
EpsilonFreeProductFst3<Fst1, Fst2, Fst3>
epsilon_free_compose(Fst1 fst1, Fst2 fst2, Fst3 fst3)
{
    return EpsilonFreeProductFst3<Fst1, Fst2, Fst3>(std::move(fst1),
        std::move(fst2), std::move(fst3));
}
@

@<test_fst_product3.cc@>=
#include "fst.h"
#include <iostream>

int main()
{
    Fst<int, int> fst1(FstData<int, int> {
        {0, 1, 2, 3, 4},
        {0, 1, 2, 3},
        {
            {0, 0}, {1, 1}, {2, 2}, {3, 3},
        },
        {
            {0, 1}, {1, 2}, {2, 3}, {3, 4},
        },
        {
            {0, 0}, {1, 0}, {2, 0}, {3, 0},
        },
        {
            {0, "a"}, {1, "b"}, {2, "a"}, {3, "b"}
        },
        {
            {0, "a"}, {1, "b"}, {2, "a"}, {3, "b"}
        },
        0,
        4
    });

    Fst<int, int> fst2(FstData<int, int> {
        {0},
        {0, 1, 2, 3, 4, 5, 6, 7},
        {
            {0, 0}, {1, 0}, {2, 0},
            {3, 0}, {4, 0}, {5, 0},
            {6, 0}, {7, 0}
        },
        {
            {0, 0}, {1, 0}, {2, 0},
            {3, 0}, {4, 0}, {5, 0},
            {6, 0}, {7, 0}
        },
        {
            {0, 0}, {1, 1}, {2, 1},
            {3, 1}, {4, 0}, {5, 1},
            {6, 1}, {7, 1}
        },
        {
            {0, "a"}, {1, "a"}, {2, "a"},
            {3, "b"}, {4, "b"}, {5, "b"},
            {6, "<eps>"}, {7, "<eps>"},
        },
        {
            {0, "a"}, {1, "b"}, {2, "<eps>"},
            {3, "a"}, {4, "b"}, {5, "<eps>"},
            {6, "a"}, {7, "b"},
        },
        0,
        0
    });

    Fst<int, int> fst3(FstData<int, int> {
        {0, 1, 2, 3, 4},
        {0, 1, 2, 3},
        {
            {0, 0}, {1, 1}, {2, 2}, {3, 3}
        },
        {
            {0, 1}, {1, 2}, {2, 3}, {3, 4}
        },
        {
            {0, 0}, {1, 0}, {2, 0}, {3, 0}
        },
        {
            {0, "b"}, {1, "a"}, {2, "b"}, {3, "a"}
        },
        {
            {0, "b"}, {1, "a"}, {2, "b"}, {3, "a"}
        },
        0,
        4
    });

    auto fst = compose(fst1, fst2, fst3);

    std::unordered_map<typename decltype(fst)::Vertex, double> d;
    std::unordered_map<typename decltype(fst)::Vertex,
        typename decltype(fst)::Edge> pi;

    std::tie(d, pi) = shortest_path(fst, fst.start());

    for (auto &p: d) {
        std::cout << "d[(" << std::get<0>(p.first) << ", "
            << std::get<1>(p.first) << ", " << std::get<2>(p.first)
            << ")]=" << p.second << std::endl;
    }

    for (auto &e: backtrack(fst, fst.end(), pi)) {
        std::cout << "(" << std::get<0>(e) << ", "
            << std::get<1>(e) << ", " << std::get<2>(e) << ") "
            << fst.input(e) << ":" << fst.output(e)
            << std::endl;
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
#include <utility>
#include <tuple>
#include <list>

@<graph data@>
@<graph@>
@<depth first search@>
@<weighted graph data@>
@<weighted graph@>
@<shortest path@>
@<backtrack shortest path@>
@<fst data@>
@<fst@>
@<self-loop fst@>
@<two-way product fst@>
@<three-way product fst@>

#endif
@

@<fst.cc@>=
#include "fst.h"

@<self-loop fst impl@>

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

\section{Range Graph}

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

\end{document}
