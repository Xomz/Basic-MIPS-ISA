SRC = src
SOURCES = $(shell find $(SRC) -name "*.md")
PDFS = $(SOURCES:$(SRC)/%.md=%.pdf)

all: $(PDFS)

debug:
	$(info SOURCES is $(SOURCES))
	$(info PDFS is $(PDFS))

%.pdf:$(SRC)/%.md
	pandoc -s $< -o $@

clean:
	rm -rf *.pdf

.PHONY: all clean debug
