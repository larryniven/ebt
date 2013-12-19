#ifndef EBT_RANGE_H
#define EBT_RANGE_H

namespace ebt {

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
            return b_ == e_;
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
