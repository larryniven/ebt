#include "sparse_vector.h"
#include "unordered_map.h"
#include <vector>
#include <cmath>

namespace ebt {

    SparseVector::SparseVector(std::initializer_list<
            std::pair<std::string const, double>> list)
        : map_(list)
    {}
    
    SparseVector::SparseVector(std::unordered_map<std::string, double> map)
        : map_(std::move(map))
    {}
    
    double& SparseVector::operator()(std::string const &key)
    {
        return map_[key];
    }
    
    double SparseVector::operator()(std::string const &key) const
    {
        if (in(key, map_)) {
            return map_.at(key);
        } else {
            return 0;
        }
    }
    
    SparseVector & SparseVector::operator+=(SparseVector const &that)
    {
        for (auto &p: that.map_) {
            map_[p.first] += p.second;
            if (std::fabs(map_[p.first]) < 1e-300) {
                map_.erase(p.first);
            }
        }
        return *this;
    }
    
    SparseVector & SparseVector::operator-=(SparseVector const &that)
    {
        for (auto &p: that.map_) {
            map_[p.first] -= p.second;
            if (std::fabs(map_[p.first]) < 1e-300) {
                map_.erase(p.first);
            }
        }
        return *this;
    }
    
    SparseVector & SparseVector::operator*=(double scalar)
    {
        std::vector<std::string> to_erase;
    
        for (auto &p: map_) {
            p.second *= scalar;
            if (std::fabs(p.second) < 1e-300) {
                to_erase.push_back(p.first);
            }
        }
    
        for (auto &k: to_erase) {
            map_.erase(k);
        }
        return *this;
    }
    
    SparseVector & SparseVector::operator/=(double scalar)
    {
        std::vector<std::string> to_erase;
    
        for (auto &p: map_) {
            p.second /= scalar;
            if (std::fabs(p.second) < 1e-300) {
                to_erase.push_back(p.first);
            }
        }
    
        for (auto &k: to_erase) {
            map_.erase(k);
        }
        return *this;
    }
    
    SparseVector::const_iterator SparseVector::begin() const
    {
        return map_.begin();
    }
    
    SparseVector::const_iterator SparseVector::end() const
    {
        return map_.end();
    }
    
    SparseVector::iterator SparseVector::begin()
    {
        return map_.begin();
    }
    
    SparseVector::iterator SparseVector::end()
    {
        return map_.end();
    }
    
    int SparseVector::size() const
    {
        return map_.size();
    }
    
    double dot(SparseVector const &a, SparseVector const &b)
    {
        if (b.map_.size() < a.map_.size()) {
            return dot(b, a);
        }
    
        double result = 0;
        for (auto &p: a) {
            result += p.second * b(p.first);
        }
        return result;
    }
    
    bool in(std::string const &key, SparseVector const &v)
    {
        return in(key, v.map_);
    }
    
}
