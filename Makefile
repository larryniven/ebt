CXXFLAGS += -std=c++11

tests = test_dfs \
    test_shortest \
    test_fst_product2 \
    test_fst_product3 \
    test_product \
    test_map \
    test_filter \
    test_chain \
    test_uni_ref

.PHONY: all clean doc check

all: ebt.h fst.h libebt.a

check: all $(tests)

doc: ebt.pdf fst.pdf

clean:
	-rm *.o
	-rm *.h *.cc
	-rm *.tex *.log *.aux *.pdf *.toc
	-rm libebt.a
	-rm $(tests)

fst.h: fst.w
	tangle.py fst.w fst.h > fst.h

test_dfs.cc: fst.w
	tangle.py fst.w test_dfs.cc > test_dfs.cc

test_shortest.cc: fst.w
	tangle.py fst.w test_shortest.cc > test_shortest.cc

test_fst_product2.cc: fst.w
	tangle.py fst.w test_fst_product2.cc > test_fst_product2.cc

test_fst_product3.cc: fst.w
	tangle.py fst.w test_fst_product3.cc > test_fst_product3.cc

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

fst.tex: fst.w
	weave.py fst.w > fst.tex

fst.pdf: fst.tex
	pdflatex fst
	pdflatex fst

ebt.cc: ebt.w
	tangle.py ebt.w ebt.cc > ebt.cc

ebt.h: ebt.w
	tangle.py ebt.w ebt.h > ebt.h

ebt.tex: ebt.w
	weave.py ebt.w > ebt.tex

ebt.pdf: ebt.tex
	pdflatex ebt
	pdflatex ebt

libebt.a: ebt.o
	$(AR) rcs $@ $^

ebt.o: ebt.h

test_dfs.o: fst.h ebt.h
test_shortest.o: fst.h ebt.h
test_product2.o: fst.h ebt.h
test_product3.o: fst.h ebt.h
test_product.o: ebt.h
test_map.o: ebt.h
test_filter.o: ebt.h
test_chain.o: ebt.h
test_smart_ref.o: ebt.h

test_dfs: test_dfs.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_shortest: test_shortest.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_product2: test_product2.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_product3: test_product3.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_product: test_product.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_map: test_map.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_filter: test_filter.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_chain: test_chain.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_smart_ref: test_smart_ref.o ebt.o
	$(CXX) $(CXXFLAGS) -o $@ $^

