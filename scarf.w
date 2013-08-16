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

class LatticeParser {
public:
    struct Edge {
        int start;
        int end;
        std::string label;
    };

    struct Lattice {
        std::string id;
        std::vector<Edge> edges;
    };

    LatticeParser(std::istream &is);

    ebt::Option<Lattice> parse_utterance();
    std::vector<Lattice> parse();

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

ebt::Option<typename LatticeParser::Lattice>
LatticeParser::parse_utterance()
{
    std::string line;
    typename LatticeParser::Lattice utt;

    std::getline(is_, line);

    if (!is_) {
        return ebt::none<typename LatticeParser::Lattice>();
    }

    utt.id = std::move(line);

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

        typename LatticeParser::Edge e {std::stoi(parts[0]),
            std::stoi(parts[1]), parts[2]};

        utt.edges.push_back(e);
    }

    return ebt::some(utt);
}

std::vector<typename LatticeParser::Lattice> LatticeParser::parse()
{
    std::vector<typename LatticeParser::Lattice> result;

    while (true) {
        ebt::Option<typename LatticeParser::Lattice> utt
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

    std::vector<typename LatticeParser::Lattice> utts
        = parser.parse();
    std::cout << utts.size() << std::endl;

    return 0;
}
@

\end{document}
