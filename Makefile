CXX=litg++
CXXFLAGS += -std=c++11

.PHONY: all clean doc

all: ebt.o fst.o test_dfs test_shortest

doc: ebt.pdf fst.pdf

clean:
	-rm *.o
	-rm *.h *.cc
	-rm *.tex *.log *.aux *.pdf
	-rm test_dfs test_shortest

fst.cc: fst.w
	tangle.py fst.w fst.cc > fst.cc

fst.h: fst.w
	tangle.py fst.w fst.h > fst.h

test_dfs.cc: fst.w
	tangle.py fst.w test_dfs.cc > test_dfs.cc

test_shortest.cc: fst.w
	tangle.py fst.w test_shortest.cc > test_shortest.cc

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

ebt.o: ebt.h
fst.o: fst.h ebt.h
test_dfs.o: fst.h ebt.h
test_shortest.o: fst.h ebt.h

test_dfs: test_dfs.o ebt.o fst.o
	$(CXX) $(CXXFLAGS) -o $@ $^

test_shortest: test_shortest.o ebt.o fst.o
	$(CXX) $(CXXFLAGS) -o $@ $^
