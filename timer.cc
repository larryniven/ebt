#include "timer.h"
#include <iostream>

namespace ebt {

    Timer::Timer()
    {
        std::time(&before);
    }
    
    Timer::~Timer()
    {
        std::time(&after);
        int seconds = int(std::difftime(after, before));
    
        std::cout << seconds / 60 << " mins " << seconds % 60 << " secs"
            << std::endl;
    }

}
