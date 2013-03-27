CXX=litg++
CXXFLAGS += -std=c++11

.PHONY: all clean doc

all: ebt.o fst.o

doc: ebt.pdf fst.pdf

clean:
	-rm *.o
	-rm *.h *.cc
	-rm *.tex *.log *.aux *.pdf

fst.cc: fst.w
	tangle.py fst.w fst.cc > fst.cc

fst.h: fst.w
	tangle.py fst.w fst.h > fst.h

fst.tex: fst.w
	weave.py fst.w > fst.tex

fst.pdf: fst.tex
	pdflatex fst

ebt.cc: ebt.w
	tangle.py ebt.w ebt.cc > ebt.cc

ebt.h: ebt.w
	tangle.py ebt.w ebt.h > ebt.h

ebt.tex: ebt.w
	weave.py ebt.w > ebt.tex

ebt.pdf: ebt.tex
	pdflatex ebt

ebt.o: ebt.h
fst.o: fst.h ebt.h

