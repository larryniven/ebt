#include "ebt/args.h"
#include <iostream>
#include <unordered_set>
#include "ebt/string.h"
#include "ebt/unordered_map.h"
#include "ebt/unordered_set.h"

namespace ebt {

    void usage(ArgumentSpec spec)
    {
        std::cout << "usage: " << spec.name << " args..." << std::endl;
        std::cout << std::endl;
        std::cout << spec.description << std::endl;
        std::cout << std::endl;
        std::cout << "Arguments:" << std::endl;
        std::cout << std::endl;
    
        for (auto &i: spec.keys) {
            std::cout << "    --" << i.name;
            for (int k = 0; k < 24 - int(i.name.size()); ++k) {
                std::cout << " ";
            }
            std::cout << i.help_str << std::endl;
        }
    
        std::cout << std::endl;
    }
    
    std::unordered_map<std::string, std::string>
    parse_args(int argc, char *argv[], ArgumentSpec spec)
    {
        std::unordered_set<std::string> required;
        std::unordered_set<std::string> keys;
    
        for (auto &i: spec.keys) {
            if (i.required) {
                required.insert(i.name);
            }
            keys.insert(i.name);
        }
    
        std::unordered_map<std::string, std::string> result;
        int i = 1;
        while (i < argc) {
            if (ebt::startswith(argv[i], "--")) {
                std::string key = std::string(argv[i]).substr(2);
                if (!ebt::in(key, keys)) {
                    std::cout << "unknown argument --" << key << std::endl;
                    exit(1);
                }
                if (i + 1 < argc && !ebt::startswith(argv[i + 1], "--")) {
                    std::string value = std::string(argv[i + 1]);
                    result[key] = value;
                    ++i;
                } else {
                    result[key] = "";
                }
            } else {
                std::cout << "unknown argument \"" << argv[i] << "\"" << std::endl;
                exit(1);
            }
            ++i;
        }
    
        for (auto &i: required) {
            if (!ebt::in(i, result)) {
                std::cout << "argument --" << i << " is required" << std::endl;
                exit(1);
            }
        }
    
        return result;
    }

}
