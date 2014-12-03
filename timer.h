#ifndef EBT_TIMER_H
#define EBT_TIMER_H

#include <ctime>

namespace ebt {

    struct Timer {
        time_t before;
        time_t after;
    
        Timer();
    
        ~Timer();
    };

    template <int i>
    struct accu_timer {
        time_t before;
        time_t after;

        static double secs;

        accu_timer()
        {
            std::time(&before);
        }

        ~accu_timer()
        {
            std::time(&after);
            secs += std::difftime(after, before);
        }
    };

    template <int i> double accu_timer<i>::secs = 0;
}

#endif
