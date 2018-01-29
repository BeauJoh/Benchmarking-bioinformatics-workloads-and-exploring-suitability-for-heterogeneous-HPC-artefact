.PHONY: results document

#all:	results document
#all:	latexmk
all:	latexmk
#all: 	texliveonfly

texliveonfly:
	python ./styles/texliveonfly.py document.tex

latexmk:
	/usr/local/texlive/2015basic/bin/x86_64-darwin/latexmk -pdf

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
