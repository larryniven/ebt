#ifndef EBT_ARGS_H
#define EBT_ARGS_H

#include <string>
#include <vector>
#include <unordered_map>

namespace ebt {

    struct Arg {
        std::string name;
        std::string help_str;
        bool required;
    };
    
    struct ArgumentSpec {
        std::string name;
        std::string description;
        std::vector<Arg> keys;
    };
    
    void usage(ArgumentSpec spec);
    
    std::unordered_map<std::string, std::string>
    parse_args(int argc, char *argv[], ArgumentSpec spec);

}

#endif
