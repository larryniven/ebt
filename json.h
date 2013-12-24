#ifndef EBT_JSON_H
#define EBT_JSON_H

#include <vector>
#include <ostream>
#include <istream>
#include <exception>
#include <string>
#include <unordered_map>
#include <utility>
#include "string.h"

namespace ebt {

    namespace json {

        void dump(std::string const& str, std::ostream& os);
        void dump(int i, std::ostream& os);
        void dump(double d, std::ostream& os);

        template <class U, class V>
        void dump(std::pair<U, V> const& p, std::ostream& os)
        {
            os << "(";
            dump(p.first, os);
            os << ", ";
            dump(p.second, os);
            os << ")";
        }

        template <class T>
        void dump(std::vector<T> const& vec, std::ostream& os)
        {
            os << "[";

            auto r = make_range(vec);

            while (!r.empty()) {
                dump(r.front(), os);
                r.pop_front();

                if (!r.empty()) {
                    os << ", ";
                }
            }

            os << "]";
        }

        template <class V>
        void dump(std::unordered_map<std::string, V> const& map, std::ostream& os)
        {
            os << "{";

            auto r = make_range(map);

            while (!r.empty()) {
                dump(r.front().first, os);
                os << ": ";
                dump(r.front().second, os);

                r.pop_front();

                if (!r.empty()) {
                    os << ", ";
                }
            }

            os << "}";
        }

        void expect(std::istream& is, char c);
        void whitespace(std::istream& is);

        template <class T>
        struct json_parser;

        template <>
        struct json_parser<int> {
            int parse(std::istream& is);
        };

        template <>
        struct json_parser<double> {
            double parse(std::istream& is);
        };

        template <>
        struct json_parser<std::string> {
            std::string parse(std::istream& is);
        };

        template <class T>
        struct json_parser<std::vector<T>> {
            std::vector<T> parse(std::istream& is)
            {
                std::vector<T> result;
                json_parser<T> elem_parser;

                expect(is, '[');
                is.get();
                whitespace(is);

                while (is.peek() != ']') {
                    result.push_back(elem_parser.parse(is));
                    whitespace(is);

                    if (is.peek() == ',') {
                        is.get();
                        whitespace(is);
                    } else {
                        break;
                    }
                }

                expect(is, ']');
                is.get();

                return result;
            }
        };

        template <class V>
        struct json_parser<std::unordered_map<std::string, V>> {
            std::unordered_map<std::string, V> parse(std::istream& is)
            {
                std::unordered_map<std::string, V> result;
                json_parser<V> value_parser;

                expect(is, '{');
                is.get();
                whitespace(is);

                while (is.peek() != '}') {
                    json_parser<std::string> key_parser;
                    auto key = key_parser.parse(is);

                    expect(is, ':');
                    is.get();
                    whitespace(is);

                    result[key] = value_parser.parse(is);
                    whitespace(is);

                    if (is.peek() == ',') {
                        is.get();
                        whitespace(is);
                    } else {
                        break;
                    }
                }

                expect(is, '}');
                is.get();

                return result;
            }
        };

    }
}

#endif
