#ifndef EBT_OPTION_H
#define EBT_OPTION_H

#include "either.h"

namespace ebt {

    template <class T>
    class Option {
    public:
        Option()
        {}
    
        explicit Option(T t)
            : some_(right(std::move(t)))
        {}
    
        bool has_none() const
        {
            return some_.is_left();
        }
    
        bool has_some() const
        {
            return some_.is_right();
        }
    
        T const & some() const
        {
            return some_.right();
        }
    
        T & some()
        {
            return some_.right();
        }
    
    private:
        struct None {};
    
        Either<None, T> some_;
    };
    
    template <class T>
    Option<T> some(T t)
    {
        return Option<T>(std::move(t));
    }
    
    template <class T>
    Option<T> none()
    {
        return Option<T>();
    }

}

#endif
