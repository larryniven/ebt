#ifndef EBT_FUNCTIONAL_H
#define EBT_FUNCTIONAL_H

#include "range.h"
#include <tuple>
#include <functional>
#include <memory>

namespace ebt {

    template <class range, class func, bool need_cache>
    class map_range_impl;

    template <class range, class func>
    class map_range_impl<range, func, true> {
    public:
        using value_type = typename std::result_of<func(typename range::value_type const&)>::type;

        map_range_impl(range r, func f)
            : r_(std::move(r)), f_(std::move(f)), dirty_(true)
        {}

        void pop_front()
        {
            r_.pop_front();
            dirty_ = true;
        }

        value_type const& front() const
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

        range_iterator<map_range_impl> begin()
        {
            return range_iterator<map_range_impl>(*this);
        }

        range_iterator<map_range_impl> end()
        {
            return range_iterator<map_range_impl>();
        }

    private:
        range r_;
        func f_;

        mutable value_type cache_;
        mutable bool dirty_;
    };

    template <class range, class func>
    class map_range_impl<range, func, false> {
    public:
        using value_type = typename std::result_of<func(typename range::value_type const&)>::type;

        map_range_impl(range r, func f)
            : r_(std::move(r)), f_(std::move(f))
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

        range_iterator<map_range_impl> begin()
        {
            return range_iterator<map_range_impl>(*this);
        }

        range_iterator<map_range_impl> end()
        {
            return range_iterator<map_range_impl>();
        }

    private:
        range r_;
        func f_;
    };

    template <class range, class func>
    using map_range = map_range_impl<range, func,
        !std::is_reference<typename std::result_of<func(
        typename range::value_type const&)>::type>::value>;

    template <class range, class func>
    typename std::enable_if<is_range<range>::value,
        map_range<range, func>>::type
    map(range const& r, func f)
    {
        return map_range<range, func>(r, f);
    }

    template <class container, class func>
    typename std::enable_if<!is_range<container>::value,
        map_range<range<container>, func>>::type
    map(container const& con, func f)
    {
        return map(make_range(con), f);
    }

    template <class range1, class range2>
    class zip_range {
    public:
        using value_type = std::tuple<typename range1::value_type const&,
            typename range2::value_type const&>;

        zip_range(range1 r1, range2 r2)
            : r1_(std::move(r1)), r2_(std::move(r2)), dirty_(true), result_(nullptr)
        {}

        void pop_front()
        {
            r1_.pop_front();
            r2_.pop_front();
            dirty_ = true;
        }

        value_type const& front() const
        {
            if (dirty_) {
                result_.reset(new value_type(r1_.front(), r2_.front()));
                dirty_ = false;
            }
            return *result_;
        }

        bool empty() const
        {
            return r1_.empty() || r2_.empty();
        }

        range_iterator<zip_range> begin()
        {
            return range_iterator<zip_range>(*this);
        }

        range_iterator<zip_range> end()
        {
            return range_iterator<zip_range>();
        }

    private:
        range1 r1_;
        range2 r2_;

        mutable bool dirty_;
        mutable std::shared_ptr<value_type> result_;
    };

    template <class range1, class range2>
    typename std::enable_if<
        is_range<range1>::value && is_range<range2>::value,
        zip_range<range1, range2>>::type
    zip(range1 r1, range2 r2)
    {
        return zip_range<range1, range2>(r1, r2);
    }

    template <class container1, class container2>
    typename std::enable_if<
        !is_range<container1>::value && !is_range<container2>::value,
        zip_range<range<container1>, range<container2>>>::type
    zip(container1& con1, container2& con2)
    {
        return zip(make_range(con1), make_range(con2));
    }

} 

#endif
