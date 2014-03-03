#ifndef EBT_NGRAM_H
#define EBT_NGRAM_H

#include <list>

namespace ebt {

    template <class Iterator>
    class NGramIterator : public std::iterator<
        std::input_iterator_tag,
        std::list<typename Iterator::value_type>> {
    
    public:
        NGramIterator() = default;
    
        NGramIterator(Iterator iter, Iterator end, int n)
            : iter_(iter), end_(end), n_(n)
        {
            for (int i = 0; i < n_ - 1; ++i) {
                if (iter_ != end_) {
                    value_.push_back(*iter_);
                    ++iter_;
                }
            }
            if (iter_ != end_) {
                value_.push_back(*iter_);
            }
        }
    
        NGramIterator & operator++()
        {
            if (iter_ != end_) {
                ++iter_;
            }
            if (iter_ != end_) {
                value_.pop_front();
                value_.push_back(*iter_);
            }
            return *this;
        }
    
        std::list<typename Iterator::value_type> const & operator*() const
        {
            return value_;
        }
    
        bool operator!=(NGramIterator const &that) const
        {
            return this->iter_ != that.iter_;
        }
    
    private:
        Iterator iter_;
        Iterator end_;
        int n_;
        mutable std::list<typename Iterator::value_type> value_;
    };
    
    template <class Iterable>
    class NGramIterable {
    public:
        using const_iterator = NGramIterator<
            typename std::decay<Iterable>::type::const_iterator>;
        using value_type = typename const_iterator::value_type;
    
        NGramIterable(Iterable &&iterable, int n)
            : iterable_(iterable), n_(n)
        {}
    
        const_iterator begin() const
        {
            return const_iterator(iterable_.begin(), iterable_.end(), n_);
        }
    
        const_iterator end() const
        {
            return const_iterator(iterable_.end(), iterable_.end(), n_);
        }
    
    private:
        Iterable iterable_;
        int n_;
    };
    
    template <class Iterable>
    NGramIterable<Iterable> ngram(Iterable &&iterable, int n)
    {
        return NGramIterable<Iterable>(std::forward<Iterable>(iterable), n);
    }

}

#endif
