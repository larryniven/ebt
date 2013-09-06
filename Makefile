CXXFLAGS += -std=c++11 -Wall
TANGLE = tangle.py
WEAVE = weave.py

tests = test_zip \
    test_product \
    test_map \
    test_filter \
    test_chain \
    test_uni_ref \
    test_sparse_vector \
    test_join \
    test_format \
    test_split_utf8 \
    test_print_tuple \
    test_ngram

.PHONY: all clean doc check

all: libebt.a

check: all $(tests)

doc: ebt.pdf

clean:
	-rm *.o
	-rm *.h *.cc
	-rm *.tex *.log *.aux *.pdf *.toc
	-rm libebt.a
	-rm $(tests)

# TeX

ebt.tex: ebt.w
	$(WEAVE) ebt.w > ebt.tex

# PDF

ebt.pdf: ebt.tex
	pdflatex ebt
	pdflatex ebt

# C++

ebt.cc: ebt.w
	$(TANGLE) ebt.w ebt.cc > ebt.cc

ebt.h: ebt.w
	$(TANGLE) ebt.w ebt.h > ebt.h

ebt.o: ebt.h

libebt.a: ebt.o
	$(AR) rcs $@ $^

# Tests

test_zip.cc: ebt.w
	$(TANGLE) ebt.w test_zip.cc > test_zip.cc

test_product.cc: ebt.w
	$(TANGLE) ebt.w test_product.cc > test_product.cc

test_chain.cc: ebt.w
	$(TANGLE) ebt.w test_chain.cc > test_chain.cc

test_map.cc: ebt.w
	$(TANGLE) ebt.w test_map.cc > test_map.cc

test_filter.cc: ebt.w
	$(TANGLE) ebt.w test_filter.cc > test_filter.cc

test_uni_ref.cc: ebt.w
	$(TANGLE) ebt.w test_uni_ref.cc > test_uni_ref.cc

test_sparse_vector.cc: ebt.w
	$(TANGLE) ebt.w test_sparse_vector.cc > test_sparse_vector.cc

test_join.cc: ebt.w
	$(TANGLE) ebt.w test_join.cc > test_join.cc

test_format.cc: ebt.w
	$(TANGLE) ebt.w test_format.cc > test_format.cc

test_split_utf8.cc: ebt.w
	$(TANGLE) ebt.w test_split_utf8.cc > test_split_utf8.cc

test_print_tuple.cc: ebt.w
	$(TANGLE) ebt.w test_print_tuple.cc > test_print_tuple.cc

test_ngram.cc: ebt.w
	$(TANGLE) ebt.w test_ngram.cc > test_ngram.cc

test_zip.o: ebt.h
test_product.o: ebt.h
test_map.o: ebt.h
test_filter.o: ebt.h
test_chain.o: ebt.h
test_uni_ref.o: ebt.h
test_join.o: ebt.h
test_format.o: ebt.h
test_split_utf8.o: ebt.h
test_ngram.o: ebt.h

test_zip: test_zip.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_product: test_product.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_map: test_map.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_filter: test_filter.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_chain: test_chain.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_uni_ref: test_uni_ref.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_sparse_vector: test_sparse_vector.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_join: test_join.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_format: test_format.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_split_utf8: test_split_utf8.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_print_tuple: test_print_tuple.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_ngram: test_ngram.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

