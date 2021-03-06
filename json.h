#ifndef EBT_JSON_H
#define EBT_JSON_H

#include <vector>
#include <ostream>
#include <istream>
#include <exception>
#include <string>
#include <unordered_map>
#include <utility>
#include "ebt/string.h"
#include <complex>

namespace ebt {

    namespace json {

        template <class T>
        struct json_writer;

        template <class T>
        void dump(T const& t, std::ostream& os)
        {
            json_writer<T>().write(t, os);
        }

        template <>
        struct json_writer<std::string> {
            void write(std::string const& str, std::ostream& os);
        };

        template <>
        struct json_writer<unsigned int> {
            void write(unsigned int i, std::ostream& os);
        };

        template <>
        struct json_writer<int> {
            void write(int i, std::ostream& os);
        };

        template <>
        struct json_writer<float> {
            void write(float d, std::ostream& os);
        };

        template <>
        struct json_writer<double> {
            void write(double d, std::ostream& os);
        };

        template <class T>
        struct json_writer<std::complex<T>> {
            void write(std::complex<T> const& c, std::ostream& os)
            {
                os << c;
            }
        };

        template <class U, class V>
        struct json_writer<std::pair<U, V>> {
            void write(std::pair<U, V> const& p, std::ostream& os)
            {
                os << "(";
                dump(p.first, os);
                os << ", ";
                dump(p.second, os);
                os << ")";
            }
        };

        template <int i, class... Args>
        struct write_tuple {
            void operator()(std::tuple<Args...> const& t, std::ostream& os)
            {
                write_tuple<i-1, Args...>()(t, os);
                os << ", ";
                dump(std::get<i-1>(t), os);
            }
        };

        template <class... Args>
        struct write_tuple<1, Args...> {
            void operator()(std::tuple<Args...> const& t, std::ostream& os)
            {
                dump(std::get<0>(t), os);
            }
        };

        template <class... Args>
        struct json_writer<std::tuple<Args...>> {
            void write(std::tuple<Args...> const& t, std::ostream& os)
            {
                os << "(";
                write_tuple<std::tuple_size<std::tuple<Args...>>::value, Args...>()(t, os);
                os << ")";
            }
        };

        template <class T>
        struct json_writer<std::vector<T>> {
            void write(std::vector<T> const& vec, std::ostream& os)
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
        };

        template <class K, class V>
        struct json_writer<std::unordered_map<K, V>> {
            void write(std::unordered_map<K, V> const& map, std::ostream& os)
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
        };

        void expect(std::istream& is, char c);
        void whitespace(std::istream& is);

        template <class T>
        struct json_parser;

        template <class T>
        T load(std::istream& is)
        {
            return json_parser<T>().parse(is);
        }

        template <>
        struct json_parser<int> {
            int parse(std::istream& is);
        };

        template <>
        struct json_parser<float> {
            float parse(std::istream& is);
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
        struct json_parser<std::complex<T>> {
            std::complex<T> parse(std::istream& is)
            {
                json_parser<T> t_parser;
                expect(is, '(');
                is.get();
                T real = t_parser.parse(is);
                expect(is, ',');
                is.get();
                T imag = t_parser.parse(is);
                expect(is, ')');
                is.get();
                return {real, imag};
            }
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

        template <class First, class... Args>
        struct parse_tuple {
            std::tuple<First, Args...> operator()(std::istream& is)
            {
                json_parser<First> first_parser;
                auto first = std::make_tuple(first_parser.parse(is));
                expect(is, ',');
                is.get();
                whitespace(is);
                return std::tuple_cat(first, parse_tuple<Args...>()(is));
            }
        };

        template <class Last>
        struct parse_tuple<Last> {
            std::tuple<Last> operator()(std::istream& is)
            {
                json_parser<Last> last_parser;
                return std::make_tuple(last_parser.parse(is));
            }
        };

        template <class... Args>
        struct json_parser<std::tuple<Args...>> {
            std::tuple<Args...> parse(std::istream& is)
            {
                expect(is, '(');
                is.get();
                auto result = parse_tuple<Args...>()(is);
                expect(is, ')');
                is.get();
                return result;
            }
        };

    }
}

#endif
