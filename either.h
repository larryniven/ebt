#ifndef EBT_EITHER_H
#define EBT_EITHER_H

namespace ebt {

    template <class T>
    struct Left {
        T value;
    };
    
    template <class T>
    Left<T> left(T t)
    {
        return Left<T> { std::move(t) };
    }
    
    template <class T>
    struct Right {
        T value;
    };
    
    template <class T>
    Right<T> right(T t)
    {
        return Right<T> { std::move(t) };
    }
    
    template <class L, class R>
    struct Either {
        Either()
            : is_left_(true)
        {}
    
        explicit Either(Left<L> left)
            : left_(std::move(left.value)), is_left_(true)
        {
        }
    
        explicit Either(Right<R> right)
            : right_(std::move(right.value)), is_left_(false)
        {
        }
    
        bool is_left() const
        {
            return is_left_;
        }
    
        bool is_right() const
        {
            return !is_left_;
        }
    
        L const & left() const
        {
            return left_;
        }
    
        L & left()
        {
            return left_;
        }
    
        R const & right() const
        {
            return right_;
        }
    
        R & right()
        {
            return right_;
        }
    
        bool operator==(Either const &that) const
        {
            if (this->is_left() && that.is_left()) {
                return this->left() == that.left();
            } else if (this->is_right() && that.is_right()) {
                return this->right() == that.right();
            } else {
                return false;
            }
        }
    
    private:
        L left_;
        R right_;
        bool is_left_;
    };

}

#endif
