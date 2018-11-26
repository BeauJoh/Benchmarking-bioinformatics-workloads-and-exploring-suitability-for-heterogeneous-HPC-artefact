all: output/document.pdf

output/document.md: paper/document.Rmd
	mkdir -p output
	Rscript -e "library(knitr); knit(input='paper/document.Rmd',output='output/document.md')"

output/document.pdf output/document.tex: output/document.md packages.yaml author-preamble.latex bibliography/bibliography.bib templates/ieee-longtable-fix-preamble.latex
	cp ./styles/IEEEtran.cls .
	mkdir -p output
	pandoc  --wrap=preserve \
		--filter pandoc-crossref \
		--filter pandoc-citeproc \
		--filter ./pandoc-tools/bib-filter.py \
		--number-sections \
		./packages.yaml \
		--include-before-body=./templates/ieee-longtable-fix-preamble.latex \
		-o output/document.$(subst output/document.,,$@) output/document.md
	rm ./IEEEtran.cls
		#--include-before-body=./author-preamble.latex \
		#--template=./templates/ieee.latex \
		#--csl=./styles/ieee.csl \

grammarly: output/document.md
	pkill Grammarly || true #if grammarly already exists kill it
	pandoc  --wrap=preserve \
		--filter pandoc-crossref \
		--filter pandoc-citeproc \
		--number-sections \
		-t plain \
		-o output/document.txt output/document.md #now get just the text
	open -a Grammarly output/document.txt #and open it in grammarly

results:
	cd results && make

