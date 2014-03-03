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

}

#endif
