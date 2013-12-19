#include <sstream>
#include "json.h"
#include "unit_test.h"

void test_parse_empty_string()
{
    std::string s = "\"\"";
    std::istringstream iss(s);
    ebt::json::json_parser<std::string> parser;
    ebt::assert_equals(std::string(""), parser.parse(iss));
}

void test_parse_some_string()
{
    std::string s = "\"blah\"";
    std::istringstream iss(s);
    ebt::json::json_parser<std::string> parser;
    ebt::assert_equals(std::string("blah"), parser.parse(iss));
}

void test_parse_quoted_string()
{
    std::string s = "\"\\\"blah\\\"\"";
    std::istringstream iss(s);
    ebt::json::json_parser<std::string> parser;
    ebt::assert_equals(std::string("\"blah\""), parser.parse(iss));
}

void test_parse_vector_of_string()
{
    std::string s = "[\"a\", \"b\", \"c\"]";
    std::istringstream iss(s);
    ebt::json::json_parser<std::vector<std::string>> parser;
    std::vector<std::string> result = parser.parse(iss);
    ebt::assert_equals(std::string("a"), result[0]);
    ebt::assert_equals(std::string("b"), result[1]);
    ebt::assert_equals(std::string("c"), result[2]);
}

void test_parse_vector_of_int()
{
    std::string s = "[1, 2, 3]";
    std::istringstream iss(s);
    ebt::json::json_parser<std::vector<int>> parser;
    std::vector<int> result = parser.parse(iss);
    ebt::assert_equals(1, result[0]);
    ebt::assert_equals(2, result[1]);
    ebt::assert_equals(3, result[2]);
}

void test_parse_double()
{
    std::string s = "1.3";
    std::istringstream iss(s);
    ebt::json::json_parser<double> parser;
    ebt::assert_equals(1.3, parser.parse(iss));
}

void test_parse_scientific()
{
    std::string s = "1.3e-10";
    std::istringstream iss(s);
    ebt::json::json_parser<double> parser;
    ebt::assert_equals(1.3e-10, parser.parse(iss));
}

void test_parse_string_to_double_map()
{
    std::string s = "{\"a\": 1, \"b\": 2}";
    std::istringstream iss(s);
    ebt::json::json_parser<std::unordered_map<std::string, double>> parser;
    std::unordered_map<std::string, double> result = parser.parse(iss);
    ebt::assert_equals(1, result.at("a"));
    ebt::assert_equals(2, result.at("b"));
}

void test_dump_vector_of_int()
{
    std::ostringstream oss;
    std::vector<int> vec = {1, 2, 3};
    ebt::json::dump(vec, oss);
    ebt::assert_equals(std::string("[1, 2, 3]"), oss.str());
}

int main()
{
    test_parse_empty_string();
    test_parse_some_string();
    test_parse_quoted_string();
    test_parse_vector_of_string();
    test_parse_vector_of_int();
    test_parse_double();
    test_parse_scientific();

    test_dump_vector_of_int();

    return 0;
}
