# Variables {{{

# Variables - Repo Source Codde {{{

ASSETS_DIR      = assets
DOCS_DIR        = docs
INCLUDE_DIRS    = $(shell pwd)/include
OBJ_DIR         = obj
PANDOC_DATA_DIR = pandoc
SRC_DIR         = src
TARGETS_DIR     = build
TARGETS         = hello-world factorial

SOURCES := $(shell find $(SRC_DIR) \
	   -type f \
	   -name "*.c" -o \
	   -name "*.cpp" 2>/dev/null | tr '\n' ' ')
HEADERS  = $(shell find $(INCLUDE_DIRS) \
	   -name "*.h" -o \
	   -name "*.hpp" \
	   2>/dev/null | tr '\n' ' ')

GITIGNORE := $(OBJ_DIR) $(TARGETS_DIR) $(TARGETS)

# }}}

# Variables - Documentation {{{

ARCHIVE             = archive.zip
INSTALLATION_MANUAL = installation-manual.pdf
PRESENTATION        = presentation.pdf
REPORT              = report.pdf
USER_MANUAL         = user-manual.pdf

PANDOC_OPTS      := --resource-path=.:..:$(DOCS_DIR):$(ASSETS_DIR)
PANDOC_THEME_DIR := $(PANDOC_DATA_DIR)/themes
PANDOC_THEME     := onehalfdark

PANDOC_OPTS += --variable=theme:Warsaw

ifneq ($(wildcard $(PANDOC_THEME:%=$(PANDOC_THEME_DIR)/%.theme)),)
PANDOC_OPTS += $(PANDOC_THEME:%=--highlight-style=$(PANDOC_THEME_DIR)/%.theme)
endif

ifneq ($(wildcard $(PANDOC_DATA_DIR)),)
	PANDOC_OPTS += \
		       $(foreach filter,\
		       $(wildcard $(PANDOC_DATA_DIR)/filters/*.lua),\
		       --lua-filter=$(filter))
endif

DOCUMENTS     := $(REPORT) $(USER_MANUAL) $(INSTALLATION_MANUAL)
PRESENTATIONS := $(PRESENTATION)

GITIGNORE += $(DOCUMENTS) $(PRESENTATIONS)

# }}}

# Variables - Python {{{

VENV   := venv
PYTHON := ./$(VENV)/bin/python
PIP    := ./$(VENV)/bin/pip

GITIGNORE += $(VENV)

# }}}

# Variables - Compilation {{{

CC     = gcc
CCP    = g++
CFLAGS = -Wall -Wextra -Werror
LINKS  =

CFLAGS += -Wno-error=unused-parameter
CFLAGS += -Wno-error=unused-variable
CFLAGS += -Wno-error=unused-but-set-variable
CFLAGS += -fdiagnostics-color=always
CFLAGS += $(INCLUDE_DIRS:%=-I%)

# }}}

# Variables - Miscellaneous {{{

OPEN = xdg-open

# }}}

# }}}

# Rules {{{

# Rules - Custom {{{

all: warning $(VENV) $(DOCUMENTS) $(PRESENTATIONS) $(TARGETS)

.PHONY: gdb
gdb: MAKEFLAGS += --always-make --no-print-directory
gdb: CFLAGS += -g -Og
gdb:
	$(MAKE) $(MAKEFLAGS) CFLAGS="$(CFLAGS)" $(TARGETS)

.PHONY: debug
debug: MAKEFLAGS += --always-make --no-print-directory
debug: CFLAGS += -DDEBUG=1
debug:
	$(MAKE) $(MAKEFLAGS) CFLAGS="$(CFLAGS)" $(TARGETS)

.PHONY: rebuild
rebuild: MAKEFLAGS += --always-make --no-print-directory
rebuild:
	$(MAKE) $(MAKEFLAGS) $(TARGETS)

.PHONY: run
run: warning $(TARGETS)
	@for target in $(TARGETS) ; do echo ./$$target ; ./$$target ; done

clean-ipcs:
ifeq ($(shell echo "$$(id --user) < 1000" | bc), 0)
	ipcrm --all
else
	@echo This rule is meant to remove non-root ipcs resources
endif

.PHONY: watch
watch:
	$(eval INOTIFYWAIT_OPTS = --quiet --event modify)

	@while true ;\
	do \
		$(MAKE) warning --no-print-directory || exit 1 ;\
		$(MAKE) --no-print-directory $(TARGETS); \
		inotifywait $(INOTIFYWAIT_OPTS) $(SOURCES) $(HEADERS); \
	done

.PHONY: PRINT-MACROS
PRINT-MACROS:
	@make --print-data-base \
		| grep -A1 "^# makefile" \
		| grep -v "^#\|^--" \
		| sort

define WARNING_MESSAGE
\033[33m[WARNING]\033[0m: Current working directory of Makefile contains spaces.
This is known to cause bugs.

\033[36m[INFO]\033[0m:    "$(shell pwd)"
Please Try compiling by making sure the full path to this Makefile does not contain spaces.
endef

.PHONY: warning
warning:
ifneq ($(shell pwd | grep --count ' '),0)
	@echo -e '\033[33m[WARNING]\033[0m:' \
		'Current working directory of Makefile contains spaces.' \
		'This is known to cause bugs.'
	@echo -e '\033[36m[INFO]\033[0m: pwd: $(shell pwd)'
	@echo 'Please Try compiling by making sure' \
		'the full path to this Makefile does not contain spaces.'
	-exit 1
endif

# TODO: add .clang-tidy generator rule
clang-tidy:
	parallel --jobs 4 --group clang-tidy --quiet ::: $(SOURCES)

# TODO: add .clang-format generator rule
clang-format:
	clang-format --verbose -i $(SOURCES) $(HEADERS) 2>&1

setup: .clangd

.PHONY: .clangd
.clangd: GITIGNORE += .clangd
.clangd: .gitignore
	rm --force $@

	@echo Diagnostics: | tee --append $@
	@echo '  UnusedIncludes: Strict' | tee --append $@
	@echo '  MissingIncludes: Strict' | tee --append $@
	@echo CompileFlags: | tee --append $@
	@echo '  Add:' | tee --append $@

	@for flag in $(CFLAGS) ; do echo "    - $$flag" | tee --append $@ ; done

.gitignore:
ifneq ($(shell git rev-parse --show-toplevel 2>/dev/null),)
	$(eval APPEND_GITIGNORE := tr ' ' '\n' | tee --append $@)
	@echo $(GITIGNORE) | tr ' ' '\n' | tee $@
	@echo | $(APPEND_GITIGNORE)

	$(eval IGNORE_API = https://www.toptal.com/developers/gitignore/api)

ifneq ($(SOURCES),)
	curl --silent --location $(IGNORE_API)/c >> $@
endif
ifneq ($(VENV),)
	curl --silent --location $(IGNORE_API)/python >> $@
endif

endif


.PHONY: clean
clean:
	@printf "\n\033[31m"
	@printf "########################\n"
	@printf "Cleaning ...\n" $@
	@printf "########################\n"
	@printf "\033[0m\n"
	rm --force $(TARGETS) $(DOCUMENTS) $(PRESENTATIONS)
	rm --recursive --force $(OBJ_DIR) $(VENV)
	find . -type f -name '*.pyc' -delete

help:
	man

# }}}

# Rules - Documentation {{{

$(PRESENTATIONS): %.pdf: $(DOCS_DIR)/%.md
	pandoc $(PANDOC_OPTS) --to=beamer --output=$@ $<

$(DOCUMENTS): %.pdf: $(DOCS_DIR)/%.md
	pandoc $(PANDOC_OPTS) --output=$@ $<

archive: $(ARCHIVE)

.PHONY: $(ARCHIVE)
$(ARCHIVE): $(DOCUMENTS) $(PRESENTATIONS)
	git archive --output=$@ $(^:%=--add-file=%) HEAD

# }}}

# Rules - Compilation {{{

$(OBJ_DIR)/%.c.o: %.c $(HEADERS)
	@printf "\n\033[31m"
	@printf "########################\n"
	@printf "Building %s\n" $@
	@printf "########################\n"
	@printf "\033[0m\n"
	mkdir --parents "$$(dirname "$@")"
	$(CC) $(CFLAGS) -c -o $@ $<

$(OBJ_DIR)/%.cpp.o: %.cpp $(HEADERS)
	@printf "\n\033[31m"
	@printf "########################\n"
	@printf "Building %s\n" $@
	@printf "########################\n"
	@printf "\033[0m\n"
	mkdir --parents "$$(dirname "$@")"
	$(CCP) $(CFLAGS) -c -o $@ $<

# TODO: Add Parallel Compilation

_SOURCES = hello-world
hello-world: $(_SOURCES:%=$(OBJ_DIR)/$(SRC_DIR)/%.c.o)
	$(CC) $(CFLAGS) -o $@ $^

_SOURCES = factorial
factorial: $(_SOURCES:%=$(OBJ_DIR)/$(SRC_DIR)/%.cpp.o)
	$(CCP) $(CFLAGS) -o $@ $^

# }}}

# Rules - Python {{{

$(VENV): $(VENV)/bin/activate .gitignore

$(VENV)/bin/activate: requirements.txt
	python3 -m venv $(VENV)
	$(PIP) install --requirement $<

# }}}

# }}}

# vim: foldmethod=marker foldlevel=1
