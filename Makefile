NAME      = luamplib
FORMAT    = luatex

DTX       = $(NAME).dtx
DOC       = $(NAME).pdf
STY       = $(NAME).sty
LUA       = $(NAME).lua
TEST      = test-$(NAME)-plain.tex test-$(NAME)-latex.tex

UNPACKED  = $(STY) $(LUA)
GENERATED = $(UNPACKED) $(DOC)
SOURCES   = $(DTX) README NEWS Makefile $(TEST)

DOCFILES  = $(DOC) $(TEST) README NEWS
SRCFILES  = $(DTX) Makefile
RUNFILES  = $(STY) $(LUA)

ALL       = $(SRCFILES) $(DOCFILES) $(RUNFILES)

TEXMFDIR  = ./texmf
RUNDIR    = $(TEXMFDIR)/tex/$(FORMAT)/$(NAME)
DOCDIR    = $(TEXMFDIR)/doc/$(FORMAT)/$(NAME)
SRCDIR    = $(TEXMFDIR)/source/$(FORMAT)/$(NAME)

CTAN_ZIP  = $(NAME).zip
TDS_ZIP   = $(NAME).tds.zip
ZIPS      = $(CTAN_ZIP) $(TDS_ZIP)

all: $(GENERATED)
doc: $(DOC)
unpack: $(UNPACKED)
ctan: check $(CTAN_ZIP)
tds: $(TDS_ZIP)
world: all ctan

.PHONY: all doc unpack ctan tds check world

%.pdf: %.dtx
	lualatex --interaction=batchmode $< >/dev/null

$(UNPACKED): $(DTX)
	luatex -interaction=batchmode $< >/dev/null

check: $(UNPACKED)
	luatex   -interaction=batchmode test-$(NAME)-plain.tex  >/dev/null
	lualatex -interaction=batchmode test-$(NAME)-latex.tex  >/dev/null
	! grep "blank space"              test-$(NAME)-plain.log
	! grep "blank space"              test-$(NAME)-latex.log

$(CTAN_ZIP): $(SOURCES) $(DOC) $(TDS_ZIP)
	@echo "Making $@ for CTAN upload."
	@$(RM) -- $@
	@mkdir -p $(NAME)
	@cp -f $(SOURCES) $(DOC) $(NAME)
	@zip -9 -r $@ $(TDS_ZIP) $(NAME) >/dev/null
	@rm -rf $(NAME)

define run-install
@mkdir -p $(RUNDIR) && cp $(RUNFILES) $(RUNDIR)
@mkdir -p $(DOCDIR) && cp $(DOCFILES) $(DOCDIR)
@mkdir -p $(SRCDIR) && cp $(SRCFILES) $(SRCDIR)
endef

$(TDS_ZIP): TEXMFDIR=./tmp-texmf
$(TDS_ZIP): $(ALL)
	@echo "Making TDS-ready archive $@."
	@$(RM) -- $@
	@if test -e $(TEXMFDIR); then echo 'bad TEXMFDIR'; false; fi
	$(run-install)
	@cd $(TEXMFDIR) && zip -q -9 ../$@ -r .
	@$(RM) -r -- $(TEXMFDIR)

.PHONY: install clean mrproper help

install: check $(ALL)
	@echo "Installing in '$(TEXMFDIR)'."
	$(run-install)

clean:
	@latexmk -silent -c $(DTX) *.tex >/dev/null
	@rm -f -- *.log test*.pdf

mrproper: clean
	@rm -f -- $(GENERATED) $(ZIPS)

help:
	@echo '$(NAME) makefile targets:'
	@echo '                      help - (this message)'
	@echo '                       all - (default target) all generated files'
	@echo '                     world - synonymous for ctan'
	@echo '                    unpack - extract all files'
	@echo '                       doc - compile documentation'
	@echo '                      ctan - run check & generate archive for CTAN'
	@echo '                       tds - generate a TDS compliant archive'
	@echo '                     check - run the test files'
	@echo '   install TEXMFDIR=<path> - install in <path>'
