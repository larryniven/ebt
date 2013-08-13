CXXFLAGS += -std=c++11 -Wall

tests = test_dfs \
    test_shortest \
    test_fst_product2 \
    test_fst_product3 \
    test_zip \
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

all: ebt.h fst.h scarf libebt.a

check: all $(tests)

doc: ebt.pdf fst.pdf scarf.pdf

clean:
	-rm *.o
	-rm *.h *.cc
	-rm *.tex *.log *.aux *.pdf *.toc
	-rm libebt.a
	-rm scarf
	-rm $(tests)

# TeX

fst.tex: fst.w
	weave.py fst.w > fst.tex

ebt.tex: ebt.w
	weave.py ebt.w > ebt.tex

scarf.tex: scarf.w
	weave.py scarf.w > scarf.tex

# PDF

fst.pdf: fst.tex
	pdflatex fst
	pdflatex fst

ebt.pdf: ebt.tex
	pdflatex ebt
	pdflatex ebt

scarf.pdf: scarf.tex
	pdflatex scarf
	pdflatex scarf

# C++ 

fst.h: fst.w
	tangle.py fst.w fst.h > fst.h

ebt.cc: ebt.w
	tangle.py ebt.w ebt.cc > ebt.cc

ebt.h: ebt.w
	tangle.py ebt.w ebt.h > ebt.h

scarf.h: scarf.w
	tangle.py scarf.w scarf.h > scarf.h

scarf.cc: scarf.w
	tangle.py scarf.w scarf.cc > scarf.cc

scarf.o: scarf.h
ebt.o: ebt.h

libebt.a: ebt.o
	$(AR) rcs $@ $^

scarf: scarf.o libebt.a
	$(CXX) $(CXXFLAGS) -o $@ $^

# Tests

test_dfs.cc: fst.w
	tangle.py fst.w test_dfs.cc > test_dfs.cc

test_shortest.cc: fst.w
	tangle.py fst.w test_shortest.cc > test_shortest.cc

test_fst_product2.cc: fst.w
	tangle.py fst.w test_fst_product2.cc > test_fst_product2.cc

test_fst_product3.cc: fst.w
	tangle.py fst.w test_fst_product3.cc > test_fst_product3.cc

test_zip.cc: ebt.w
	tangle.py ebt.w test_zip.cc > test_zip.cc

test_product.cc: ebt.w
	tangle.py ebt.w test_product.cc > test_product.cc

test_chain.cc: ebt.w
	tangle.py ebt.w test_chain.cc > test_chain.cc

test_map.cc: ebt.w
	tangle.py ebt.w test_map.cc > test_map.cc

test_filter.cc: ebt.w
	tangle.py ebt.w test_filter.cc > test_filter.cc

test_uni_ref.cc: ebt.w
	tangle.py ebt.w test_uni_ref.cc > test_uni_ref.cc

test_sparse_vector.cc: ebt.w
	tangle.py ebt.w test_sparse_vector.cc > test_sparse_vector.cc

test_join.cc: ebt.w
	tangle.py ebt.w test_join.cc > test_join.cc

test_format.cc: ebt.w
	tangle.py ebt.w test_format.cc > test_format.cc

test_split_utf8.cc: ebt.w
	tangle.py ebt.w test_split_utf8.cc > test_split_utf8.cc

test_print_tuple.cc: ebt.w
	tangle.py ebt.w test_print_tuple.cc > test_print_tuple.cc

test_ngram.cc: ebt.w
	tangle.py ebt.w test_ngram.cc > test_ngram.cc

test_dfs.o: fst.h ebt.h
test_shortest.o: fst.h ebt.h
test_product2.o: fst.h ebt.h
test_product3.o: fst.h ebt.h
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

test_dfs: test_dfs.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_shortest: test_shortest.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_fst_product2: test_fst_product2.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_fst_product3: test_fst_product3.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

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

