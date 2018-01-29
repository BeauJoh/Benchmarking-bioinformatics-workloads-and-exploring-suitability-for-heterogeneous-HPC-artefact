.PHONY: results document

#all:	results document
#all:	latexmk
all:	latexmk
#all: 	texliveonfly
LATEXMK?=latexmk

texliveonfly:
	python ./styles/texliveonfly.py document.tex

latexmk:
	$(LATEXMK) -pdf

results:
	cd results && make

document: deluxetable.sty
	latex document 			\
	&& bibtex document 		\
	&& latex document 		\
	&& latex document 		\
	&& pdflatex document.tex

deluxetable.sty: styles/deluxetable.sty
	cp styles/$@ $@

clean:
	rm document.aux document.log document.pdf 	\
	   document.bbl document.blg document.dvi	\
	   document.fls document.fdb_latexmk		\
	&& cd results && make clean && cd ..
