#ifndef EBT_BVECTOR_H
#define EBT_BVECTOR_H

#include <vector>
#include <unordered_map>
#include <tuple>

namespace ebt {

    template <class T>
    struct bvector {
        T data;
    };

    template <class T>
    bvector<T> make_bvector(T&& t)
    {
        return bvector<T>{std::forward<T>(t)};
    }

    template <class T>
    struct dot_op;

    template <class T>
    struct dot_op<std::vector<T>> {
        double operator()(bvector<std::vector<T>> const& v1,
            bvector<std::vector<T>> const& v2)
        {
            if (v1.size() > v2.size()) {
                return (*this)(v2, v1);
            }

            double sum = 0;

            for (int i = 0; i < v1.data.size(); ++i) {
                sum += v1.data[i] * v2.data[i];
            }

            return sum;
        }
    };

    template <class T>
    struct dot_op<std::vector<T> const&> {
        double operator()(bvector<std::vector<T> const&> const& v1,
            bvector<std::vector<T> const&> const& v2)
        {
            double sum = 0;

            for (int i = 0; i < v1.data.size(); ++i) {
                sum += v1.data[i] * v2.data[i];
            }

            return sum;
        }
    };

    template <class T>
    struct dot_op<std::unordered_map<std::string, T> const&> {
        double operator()(bvector<std::unordered_map<std::string, T> const&> const& v1,
            bvector<std::unordered_map<std::string, T> const&> const& v2)
        {
            if (v1.data.size() > v2.data.size()) {
                return (*this)(v2, v1);
            }

            double sum = 0;

            for (auto& p: v1.data) {
                sum += p.second * v2.data.at(p.first);
            }

            return sum;
        }
    };

    template <class T>
    struct dot_op<std::unordered_map<std::string, T>> {
        double operator()(bvector<std::unordered_map<std::string, T>> const& v1,
            bvector<std::unordered_map<std::string, T>> const& v2)
        {
            if (v1.data.size() > v2.data.size()) {
                return (*this)(v2, v1);
            }

            double sum = 0;

            for (auto& p: v1.data) {
                sum += p.second * v2.data.at(p.first);
            }

            return sum;
        }
    };

    template <class T>
    struct dot_op<std::unordered_map<std::string, std::vector<T>>> {
        double operator()(bvector<std::unordered_map<std::string, std::vector<T>>> const& v1,
            bvector<std::unordered_map<std::string, std::vector<T>>> const& v2)
        {
            if (v1.data.size() > v2.data.size()) {
                return (*this)(v2, v1);
            }

            double sum = 0;

            for (auto& p: v1.data) {
                auto& u1 = v1.data.at(p.first);
                auto& u2 = v2.data.at(p.first);

                if (u1.size() == 0 || u2.size() == 0) {
                    continue;
                }
                for (int i = 0; i < u1.size(); ++i) {
                    sum += u1[i] * u2[i];
                }
            }

            return sum;
        }
    };

    template <class T>
    struct dot_op<std::unordered_map<std::string, std::vector<T>> const&> {
        double operator()(bvector<std::unordered_map<std::string, std::vector<T>> const&> const& v1,
            bvector<std::unordered_map<std::string, std::vector<T>> const&> const& v2)
        {
            if (v1.data.size() > v2.data.size()) {
                return (*this)(v2, v1);
            }

            double sum = 0;

            for (auto& p: v1.data) {
                auto& u1 = v1.data.at(p.first);
                auto& u2 = v2.data.at(p.first);

                if (u1.size() == 0 || u2.size() == 0) {
                    continue;
                }
                for (int i = 0; i < u1.size(); ++i) {
                    sum += u1[i] * u2[i];
                }
            }

            return sum;
        }
    };

    template <int i, class... Args>
    struct dot_op_each {
        double operator()(bvector<std::tuple<Args...>> const& v1,
            bvector<std::tuple<Args...>> const& v2)
        {
            return dot(make_bvector(std::get<i>(v1.data)), make_bvector(std::get<i>(v2.data)))
                + dot_op_each<i - 1, Args...>()(v1, v2);
        }
    };

    template <class... Args>
    struct dot_op_each<1, Args...> {
        double operator()(bvector<std::tuple<Args...>> const& v1,
            bvector<std::tuple<Args...>> const& v2)
        {
            return dot(make_bvector(std::get<0>(v1.data)), make_bvector(std::get<1>(v2.data)))
                + dot(make_bvector(std::get<1>(v1.data)), make_bvector(std::get<1>(v2.data)));
        }
    };

    template <class... Args>
    struct dot_op<std::tuple<Args...>> {
        double operator()(bvector<std::tuple<Args...>> const& v1,
            bvector<std::tuple<Args...>> const& v2)
        {
            return dot_op_each<std::tuple_size<std::tuple<Args...>>::value - 1, Args...>()(v1, v2);
        }
    };

    template <class T>
    double dot(bvector<T> const& v1, bvector<T> const& v2)
    {
        return dot_op<T>()(v1, v2);
    }

}

#endif
