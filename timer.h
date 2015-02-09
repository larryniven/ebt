#ifndef EBT_TIMER_H
#define EBT_TIMER_H

#include <ctime>
#include <chrono>

namespace ebt {

    struct Timer {
        time_t before;
        time_t after;
    
        Timer();
    
        ~Timer();
    };

    template <int i>
    struct accu_timer {
        std::chrono::high_resolution_clock::time_point before;
        std::chrono::high_resolution_clock::time_point after;

        static std::chrono::microseconds msecs;

        accu_timer()
        {
            before = std::chrono::high_resolution_clock::now();
        }

        ~accu_timer()
        {
            after = std::chrono::high_resolution_clock::now();
            msecs += std::chrono::duration_cast<std::chrono::microseconds>(after - before);
        }
    };

    template <int i> std::chrono::microseconds accu_timer<i>::msecs;
}

#endif
