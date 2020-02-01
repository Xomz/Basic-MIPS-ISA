# Building the Documents

The documents should already all be built, but if you
want to re-build the documentation and assignment instructions,
you'll need pandoc(via python3) and pdflatex.

After installing pandoc and pdflatex, do ``$make`` in this directory.

# Installing Pandoc and PdfLaTeX
## Ubuntu
```bash
sudo apt-get install texlive-latex-base texlive-fonts-recommended 
texlive-fonts-extra texlive-latex-extra python3 python3-pip pandoc
```

## MacOS
```bash
# first make sure you have brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install python3
brew cask install basictex
pip3 install pandoc
```
