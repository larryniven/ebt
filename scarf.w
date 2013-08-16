\documentclass{article}

\title{Segmental CRF}
\author{Hao Tang\\\texttt{haotang@@ttic.edu}}

\begin{document}

\maketitle

@<scarf.h@>=
#include <istream>
#include <vector>
#include <string>
#include <exception>
#include "ebt.h"
#include "fst.h"

class LatticeParser {
public:
    LatticeParser(std::istream &is);

    ebt::Option<FstData<Vertex<int>, Edge<int>>>
        parse_utterance();
    std::vector<FstData<Vertex<int>, Edge<int>>>
        parse();

private:
    std::string line_;
    std::istream &is_;
};

class ParserException : public std::exception {
public:
    ParserException(std::string msg);
    char const * what() const noexcept;
private:
    std::string msg_;
};
@

@<scarf.cc@>=
#include "scarf.h"
#include <fstream>
#include <iostream>

LatticeParser::LatticeParser(std::istream &is)
    : is_(is)
{
}

ebt::Option<FstData<Vertex<int>, Edge<int>>>
LatticeParser::parse_utterance()
{
    std::string line;
    FstData<Vertex<int>, Edge<int>> fst;

    std::getline(is_, line);

    if (!is_) {
        return ebt::none<FstData<Vertex<int>, Edge<int>>>();
    }

    std::unordered_map<int, Vertex<int>> v_at_time;

    while (true) {
        std::getline(is_, line);

        if (!is_) {
            throw ParserException("unexpected end of file");
        }

        if (line == ".") {
            break;
        }

        std::vector<std::string> parts = ebt::split(line);
        if (parts.size() != 3 && parts.size() != 5) {
            throw ParserException(
                "expect 3 parts or 5 parts in an edge but got "
                + std::to_string(parts.size()));
        }

        Edge<int> e { int(fst.edges.size()) };
        fst.edges.insert(e);

        if (!ebt::in(std::stoi(parts[0]), v_at_time)) {
            Vertex<int> v { int(fst.vertices.size()) };
            fst.vertices.insert(v);
            v_at_time[std::stoi(parts[0])] = v;
        }

        if (!ebt::in(std::stoi(parts[1]) + 1, v_at_time)) {
            Vertex<int> v { int(fst.vertices.size()) };
            fst.vertices.insert(v);
            v_at_time[std::stoi(parts[1]) + 1] = v;
        }

        fst.tail[e] = v_at_time.at(std::stoi(parts[0]));
        fst.head[e] = v_at_time.at(std::stoi(parts[1]) + 1);
        fst.input[e] = parts[2];
        fst.output[e] = parts[2];
        fst.weight[e] = 0;
    }

    return ebt::some(fst);
}

std::vector<FstData<Vertex<int>, Edge<int>>>
LatticeParser::parse()
{
    std::vector<FstData<Vertex<int>, Edge<int>>>
        result;

    while (true) {
        ebt::Option<FstData<Vertex<int>, Edge<int>>> utt
            = parse_utterance();
        if (utt.has_none()) {
            break;
        }

        result.push_back(std::move(utt.some()));
    }

    return result;
}

ParserException::ParserException(std::string msg)
    : msg_(msg)
{}

char const * ParserException::what() const noexcept
{
    return msg_.c_str();
}

int main(int argc, char *argv[])
{
    std::ifstream ifs(argv[1]);
    LatticeParser parser(ifs);

    std::vector<FstData<Vertex<int>, Edge<int>>>
        utts = parser.parse();
    std::cout << utts.size() << std::endl;

    return 0;
}
@

\end{document}
