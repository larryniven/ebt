#ifndef EBT_RANGE_H
#define EBT_RANGE_H

#include <iterator>

namespace ebt {

    template <class T>
    struct is_range {
        template <class U,
            void (U::*)() = &U::pop_front,
            bool (U::*)() const = &U::empty,
            typename U::value_type const& (U::*)() const = &U::front>
        struct check {};

        template <class U> static long f(check<U>*);
        template <class U> static char f(...);

        static bool const value = (sizeof(f<T>(nullptr)) == sizeof(long));
    };

    template <class range>
    class range_iterator
        : public std::iterator<std::input_iterator_tag,
            typename range::value_type> {
    public:
        range_iterator()
            : r_(nullptr)
        {}

        range_iterator(range& r)
            : r_(&r)
        {}

        range_iterator& operator++()
        {
            if (!r_->empty()) {
                r_->pop_front();
            }
            return *this;
        }

        typename range_iterator::value_type const& operator*()
        {
            return r_->front();
        }

        bool operator!=(range_iterator const& that)
        {
            if (that.r_ == nullptr) {
                return !r_->empty();
            }
            return true;
        }

    private:
        range* r_;
    };

    template <class container>
    class range {
    public:
        using const_iterator = typename container::const_iterator;
        using value_type = typename container::value_type;

        range(container const& con)
            : b_(con.begin()), e_(con.end())
        {}

        void pop_front()
        {
            ++b_;
        }

        value_type const& front() const
        {
            return *b_;
        }

        bool empty() const
        {
            return !(b_ != e_);
        }

        range_iterator<range> begin()
        {
            return range_iterator<range>(*this);
        }

        range_iterator<range> end()
        {
            return range_iterator<range>();
        }

    private:
        const_iterator b_;
        const_iterator e_;
    };

    template <class container>
    range<container> make_range(container const& con)
    {
        return range<container>(con);
    }

}

#endif
