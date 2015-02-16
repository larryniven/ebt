#ifndef HASHMAP_H
#define HASHMAP_H

#include <functional>
#include <ostream>
#include <vector>
#include <limits>
#include <string>

namespace ebt {

    constexpr int prime_size_scales[] = {
        7, 13, 29, 53, 97, 193, 389, 769, 1543, 3079,
        6151, 12289, 24593, 49157, 98317, 196613, 393241, 786433, 1572869, 3145739,
        6291469, 12582917, 25165843, 50331653, 100663319, 201326611, 402653189, 805306457
    };

    template <class K, class V>
    class hashmap {

    public:

        int size_scale_;

        std::hash<K> hash_func_;

        int max_probe_count_;
        int min_probe_count_;

        int size_;

        struct bucket {
            typename std::hash<K>::result_type hash;
            int base;
            int index;

            bool empty() const
            {
                return index == -1;
            }
        };

        std::vector<bucket> buckets_;
        std::vector<std::pair<K, V>> key_values_;
        std::vector<int> probe_count_dist_;

        std::ostream& print(std::ostream& os, bucket const& b)
        {
            if (!b.empty()) {
                os << b.hash << " " << key_values_.at(b.index).first << " " << b.base;
            } else {
                os << "empty";
            }

            return os;
        }

        void rehash(int size_scale)
        {
            hashmap<K, V> new_map;
            new_map.size_scale_ = size_scale;
            new_map.size_ = size_;
            new_map.key_values_ = std::move(key_values_);

            new_map.key_values_.resize(prime_size_scales[size_scale]);


#if PROBE_COUNT_DIST
            new_map.min_probe_count_ = std::numeric_limits<int>::infinity();
            new_map.max_probe_count_ = 0;
#else
            new_map.min_probe_count_ = 0;
            new_map.max_probe_count_ = buckets_.size() - 1;
#endif

            bucket b;
            b.index = -1;
            new_map.buckets_.resize(prime_size_scales[size_scale], b);

            for (int i = 0; i < buckets_.size(); ++i) {
                if (!buckets_.at(i).empty()) {
                    buckets_.at(i).base = buckets_.at(i).hash % new_map.buckets_.size();
                    new_map.insert_bucket(std::move(buckets_.at(i)));
                }
            }

            *this = std::move(new_map);
        }

        struct upsize_check {
            hashmap<K, V>& map;

            upsize_check(hashmap<K, V>& m)
                : map(m)
            {
                if (map.size_ > prime_size_scales[map.size_scale_] * 0.66) {
                    map.rehash(map.size_scale_ + 1);
                }
            }
        };

        struct downsize_check {
            hashmap<K, V>& map;

            downsize_check(hashmap<K, V>& m)
                : map(m)
            {
                if (map.size_ < prime_size_scales[map.size_scale_] * 0.33) {
                    map.rehash(map.size_scale_ - 1);
                }
            }
        };

        int search(K const& key) const
        {
            auto hash = hash_func_(key);
            int base = hash % buckets_.size();

            for (int i = base + min_probe_count_;
                    i < std::min<int>(base + max_probe_count_ + 1, buckets_.size());
                    ++i) {

                if (buckets_.at(i).hash == hash && key_values_.at(buckets_.at(i).index).first == key) {
                    return i;
                }
            }

            for (int i = 0; i < base + max_probe_count_ + 1 - int(buckets_.size()); ++i) {
                if (buckets_.at(i).hash == hash && key_values_.at(buckets_.at(i).index).first == key) {
                    return i;
                }
            }

            return -1;
        }

        std::ostream& print(std::ostream& os, hashmap<K, V> const& map)
        {
            os << min_probe_count_ << " " << max_probe_count_ << std::endl;
            os << "{" << std::endl;
            for (int i = 0; i < map.buckets_.size(); ++i) {
                os << "  " << i << ": ";
                print(os, buckets_.at(i));
                if (!buckets_.at(i).empty()) {
                    os << " " << key_values_.at(buckets_.at(i).index).second;
                }
                os << std::endl;
            }
            os << "}" << std::endl;

            return os;
        }

        int probe_count_at(int i) const
        {
            return i >= buckets_.at(i).base ? i - buckets_.at(i).base
                : i + buckets_.size() - buckets_.at(i).base;
        }

        void increment_probe_count(int count)
        {
            if (count >= probe_count_dist_.size()) {
                probe_count_dist_.resize(count + 1);
                max_probe_count_ = probe_count_dist_.size() - 1;
            }

            probe_count_dist_.at(count) += 1;

            min_probe_count_ = std::min<int>(min_probe_count_, count);
        }

        void decrement_probe_count(int count)
        {
            probe_count_dist_.at(count) -= 1;

            if (probe_count_dist_.at(count) == 0 && min_probe_count_ == count) {
                int j = count;
                for (; j < probe_count_dist_.size(); ++j) {
                    if (probe_count_dist_.at(j) != 0) {
                        break;
                    }
                }
                min_probe_count_ = j;
            }

            if (probe_count_dist_.at(count) == 0 && max_probe_count_ == count) {
                int j = count;
                for (; j >= 0; --j) {
                    if (probe_count_dist_.at(j) != 0) {
                        break;
                    }
                }
                max_probe_count_ = j;
            }

            probe_count_dist_.resize(max_probe_count_ + 1);
        }

        void insert_bucket(bucket b)
        {
            auto probe = [&](int i, int probe_count) {

                if (buckets_.at(i).empty()) {

                    buckets_.at(i) = std::move(b);

#if PROBE_COUNT_DIST
                    increment_probe_count(probe_count);
#endif

                    return true;
                }

                int probe_count_i = probe_count_at(i);

                if (probe_count_i < probe_count) {

#if PROBE_COUNT_DIST
                    increment_probe_count(probe_count);
#endif

                    using std::swap;

                    swap(buckets_.at(i), b);

#if PROBE_COUNT_DIST
                    decrement_probe_count(probe_count_i);
#endif
                }

                return false;
            };

            bool done = false;

            for (int i = b.base; !done && i < buckets_.size(); ++i) {
                int base = b.base;
                int probe_count = (i >= base ? i - base : i + buckets_.size() - base);
                done = probe(i, probe_count);
            }

            for (int i = 0; !done && i < buckets_.size(); ++i) {
                int base = b.base;
                int probe_count = (i >= base ? i - base : i + buckets_.size() - base);
                done = probe(i, probe_count);
            }

            if (!done) {
                throw std::logic_error("insertion failed");
            }
        }

    public:

        hashmap(int size_scale)
            : size_scale_(size_scale), size_(0)
        {
            bucket b;
            b.index = -1;

            buckets_.resize(prime_size_scales[size_scale_], b);
            key_values_.resize(prime_size_scales[size_scale_]);

#if PROBE_COUNT_DIST
            min_probe_count_ = std::numeric_limits<int>::infinity();
            max_probe_count_ = 0;
#else
            min_probe_count_ = 0;
            max_probe_count_ = buckets_.size() - 1;
#endif
        }

        hashmap()
            : hashmap(0)
        {}

        V const& at(K key) const
        {
            int i = search(key);

            if (i == -1) {
                throw std::out_of_range("key not found");
            }

            return key_values_.at(buckets_.at(i).index).second;
        }

        V& at(K key)
        {
            int i = search(key);

            if (i == -1) {
                throw std::out_of_range("key not found");
            }

            return key_values_.at(buckets_.at(i).index).second;
        }

        V& operator[](K key)
        {
            upsize_check rc { *this };

            bucket b;
            b.hash = hash_func_(key);
            b.index = -1;
            b.base = b.hash % buckets_.size();

            enum class probe_result {empty, key_found, swap, nothing};

            auto probe = [&](int i, int probe_count) {

                if (buckets_.at(i).empty()) {
                    if (b.empty()) {
                        key_values_.at(size_).first = std::move(key);
                        b.index = size_;
                        size_ += 1;
                        buckets_.at(i) = std::move(b);
                    } else {
                        buckets_.at(i) = std::move(b);
                    }

#if PROBE_COUNT_DIST
                    increment_probe_count(probe_count_at(i));
#endif

                    return probe_result::empty;
                }

                int probe_count_i = probe_count_at(i);

                if (probe_count_i < probe_count) {
                    using std::swap;

#if PROBE_COUNT_DIST
                    decrement_probe_count(probe_count_at(i));
#endif

                    if (b.empty()) {
                        key_values_.at(size_).first = std::move(key);
                        b.index = size_;
                        size_ += 1;
                        swap(buckets_.at(i), b);
                    } else {
                        swap(buckets_.at(i), b);
                    }

#if PROBE_COUNT_DIST
                    increment_probe_count(probe_count_at(i));
#endif


                    return probe_result::swap;
                }

                if (b.hash == buckets_.at(i).hash
                        && !buckets_.at(i).empty()
                        && key_values_.at(buckets_.at(i).index).first == key) {

                    return probe_result::key_found;
                }

                return probe_result::nothing;

            };

            for (int i = b.base; i < buckets_.size(); ++i) {
                int probe_count = (i >= b.base ? i - b.base : i + buckets_.size() - b.base);
                auto r = probe(i, probe_count);
                if (r == probe_result::key_found) {
                    return key_values_.at(buckets_.at(i).index).second;
                } else if (r == probe_result::empty) {
                    return key_values_.at(size_ - 1).second;
                }
            }

            for (int i = 0; i < buckets_.size(); ++i) {
                int probe_count = (i >= b.base ? i - b.base : i + buckets_.size() - b.base);
                auto r = probe(i, probe_count);
                if (r == probe_result::key_found) {
                    return key_values_.at(buckets_.at(i).index).second;
                } else if (r == probe_result::empty) {
                    return key_values_.at(size_ - 1).second;
                }
            }

            throw std::logic_error("insertion failed");
        }
    
        void insert(K key, V value)
        {
            (*this)[key] = std::move(value);
        }
    
        void erase(K const& key)
        {
            downsize_check rc { *this };

            int i = search(key);

            if (i == -1) {
                throw std::out_of_range("cannot find key");
            }

            key_values_.erase(key_values_.begin() + i);

            auto probe = [&](int j) {
                int prev = (j == 0 ? int(buckets_.size()) - 1 : j - 1);

                int prev_probe_count = probe_count_at(prev);

#if PROBE_DIST
                decrement_probe_count(probe_count_at(prev));
#endif

                if (buckets_.at(j).empty() || buckets_.at(j).base == j) {
                    buckets_.at(prev).index = -1;

                    return true;
                }

                buckets_.at(prev) = std::move(buckets_.at(j));

#if PROBE_DIST
                increment_probe_count(probe_count_at(prev));
#endif

                return false;
            };

            bool done = false;

            for (int j = i + 1; !done && j < buckets_.size(); ++j) {
                done = probe(j);
            }

            for (int j = 0; !done && j < buckets_.size(); ++j) {
                done = probe(j);
            }

            if (!done) {
                throw std::logic_error("erasure failed");
            }

            size_ -= 1;
        }

        bool in(K const& key) const
        {
            return search(key) != -1;
        }

        int size() const
        {
            return size_;
        }

    };

}

#endif
