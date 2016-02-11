#include "ebt/logger.h"
#include <iostream>

namespace ebt {

    logger_t logger_t::logger;

    void logger_t::start()
    {
        log_ = true;
    }

    void logger_t::stop()
    {
        log_ = false;
    }

    void logger_t::log(std::string msg) const
    {
        if (log_) {
            std::cout << msg << std::endl;
        }
    }

}
