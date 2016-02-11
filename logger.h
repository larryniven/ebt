#ifndef EBT_LOGGER_H
#define EBT_LOGGER_H

#include <string>

namespace ebt {

    struct logger_t {
        void start();
        void stop();
        void log(std::string msg) const;

        static logger_t logger;

    private:
        bool log_;
    };

}

#endif
