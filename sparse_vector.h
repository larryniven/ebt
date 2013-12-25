#ifndef EBT_SPARSE_VECTOR_H
#define EBT_SPARSE_VECTOR_H

#include <string>
#include <unordered_map>

namespace ebt {

    class SparseVector {
    public:
        using const_iterator
            = typename std::unordered_map<std::string, double>::const_iterator;
        using iterator
            = typename std::unordered_map<std::string, double>::iterator;
    
        SparseVector() = default;
    
        SparseVector(std::initializer_list<
            std::pair<std::string const, double>> list);
    
        explicit SparseVector(std::unordered_map<std::string, double> map);
    
        double& operator()(std::string const &key);
        double operator()(std::string const &key) const;
    
        SparseVector & operator+=(SparseVector const &that);
        SparseVector & operator-=(SparseVector const &that);
        SparseVector & operator*=(double scalar);
        SparseVector & operator/=(double scalar);
    
        const_iterator begin() const;
        const_iterator end() const;
    
        iterator begin();
        iterator end();
    
        int size() const;
    
        friend double dot(SparseVector const &a, SparseVector const &b);
        friend bool in(std::string const &key, SparseVector const &v);
        friend double get(ebt::SparseVector const& vec, std::string key, double default_);

        friend std::ostream& operator<<(std::ostream& os, SparseVector const& v);
    
    private:
        std::unordered_map<std::string, double> map_;
    };
    
    double dot(SparseVector const &a, SparseVector const &b);
    bool in(std::string const &key, SparseVector const &v);
    std::ostream& operator<<(std::ostream& os, SparseVector const& v);
    double get(ebt::SparseVector const& vec, std::string key, double default_);
    
}

#endif
