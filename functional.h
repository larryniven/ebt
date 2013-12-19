#ifndef EBT_FUNCTIONAL_H
#define EBT_FUNCTIONAL_H

#include "range.h"

namespace ebt {

    template <class range, class func, bool need_cache>
    class map_range_impl;

    template <class range, class func>
    class map_range_impl<range, func, true> {
    public:
        using const_iterator = typename range::const_iterator;
        using value_type = decltype(std::declval<func>()(
            *std::declval<const_iterator>()));

        map_range_impl(range r, func f)
            : r_(r), f_(f), dirty_(true)
        {}

        void pop_front()
        {
            r_.pop_front();
            dirty_ = true;
        }

        value_type const& front()
        {
            if (dirty_) {
                cache_ = f_(r_.front());
                dirty_ = false;
            }
            return cache_;
        }

        bool empty() const
        {
            return r_.empty();
        }

    private:
        range r_;
        func f_;
        value_type cache_;
        bool dirty_;
    };

    template <class range, class func>
    class map_range_impl<range, func, false> {
    public:
        using const_iterator = typename range::const_iterator;
        using value_type = typename std::decay<decltype(
            std::declval<func>()(*std::declval<const_iterator>()))>::type;

        map_range_impl(range r, func f)
            : r_(r), f_(f)
        {}

        void pop_front()
        {
            r_.pop_front();
        }

        value_type const& front() const
        {
            return f_(r_);
        }

        bool empty() const
        {
            return r_.empty();
        }

    private:
        range r_;
        func f_;
    };

    template <class range, class func>
    using map_range = map_range_impl<range, func,
        !std::is_reference<decltype(std::declval<func>()(
        *std::declval<typename range::const_iterator>()))>::value>;

    template <class container, class func>
    map_range<range<container>, func> map(container const& con, func f)
    {
        return map_range<range<container>, func>(
            make_range(con), f);
    }
} 

#endif
