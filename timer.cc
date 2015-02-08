#include "ebt/timer.h"
#include <iostream>

namespace ebt {

    Timer::Timer()
    {
        std::time(&before);
    }
    
    Timer::~Timer()
    {
        std::time(&after);
        double seconds = std::difftime(after, before);

        int minutes = int(seconds / 60);
    
        std::cout << minutes << " mins " << seconds - minutes * 60 << " secs"
            << std::endl;
    }

}
