#ifndef EBT_MAX_HEAP_H
#define EBT_MAX_HEAP_H

#include <vector>
#include <utility>
#include <unordered_map>

namespace ebt {

    template <class V, class K>
    class MaxHeap {
    private:
        std::vector<std::pair<V, K>> data_;
        std::unordered_map<V, int> index_;
    
        int parent(int i)
        {
            return i / 2;
        }
    
        int left(int i)
        {
            return 2 * i;
        }
    
        int right(int i)
        {
            return 2 * i + 1;
        }
    
        MaxHeap & max_heapify(int index)
        {
            int i = index;
            while (0 <= i && i < data_.size()) {
                int max = i;
                if (left(i) < data_.size()
                        && data_[left(i)].second > data_[max].second) {
                    max = left(i);
                }
                if (right(i) < data_.size()
                        && data_[right(i)].second > data_[max].second) {
                    max = right(i);
                }
    
                if (max == i) {
                    break;
                } else {
                    using std::swap;
                    swap(index_[data_[i].first], index_[data_[max].first]);
                    swap(data_[i], data_[max]);
                    i = max;
                }
            }
            return *this;
        }
    
    public:
        int size() const
        {
            return data_.size();
        }
    
        MaxHeap & insert(V t, K value)
        {
            data_.resize(data_.size() + 1);
            index_[t] = data_.size() - 1;
            data_.back() = std::make_pair(t, value);
            increase_key(t, value);
            return *this;
        }
    
        MaxHeap & increase_key(V t, K value)
        {
            int i = index_.at(t);
            data_[i].second = value;
            while (0 <= i && i < data_.size()
                    && value > data_[parent(i)].second) {
                using std::swap;
                swap(index_[data_[i].first], index_[data_[parent(i)].first]);
                swap(data_[i], data_[parent(i)]);
                i = parent(i);
            }
            return *this;
        }
    
        V extract_max()
        {
            V result = std::move(data_.front().first);
            using std::swap;
            swap(data_.back(), data_.front());
            index_[data_.front().first] = 0;
            index_.erase(result);
            data_.resize(data_.size() - 1);
            max_heapify(0);
            return result;
        }
    };

}

#endif
