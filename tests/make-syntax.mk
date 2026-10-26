# AI Disclosure:
# - Authorship: AI-generated
# - Models: claude-opus-5-5 (Anthropic)
# - Scope: Synthetic Makefile exercising Make-level syntax for the tests.
#
# TODO: comments continue onto the next line \
when they end with a backslash.
NOT_A_COMMENT = 1

.POSIX:
.SUFFIXES: .c .o
.PHONY: all clean
.DELETE_ON_ERROR:

# Assignments with every operator.
CC = cc
CFLAGS := -O2
LDFLAGS ::= -s
LDLIBS :::= -lm
PREFIX ?= /usr/local
CFLAGS += -Wall
DATE != date +%Y
C++FLAGS = -std=c++17
EMPTY =
SPACED   =   value with spaces
NESTED_$(CC)_NAME = nested
$(PREFIX)_DIR = dir
HASH = \#not-a-comment
VALUE = value # trailing comment
EMPTY_VALUE = # comment
LIST = \
	one \
	two \
	three

# Values are highlighted as shell code.
GPG = $$(which gpg2 || echo gpg) --homedir="$(GNUPGHOME)"
QUOTED = "a b" 'c d' \"escaped\"
SHVAR = $$HOME $${HOME:-/} $$$$ $$1
COMMENT_IN_QUOTES = "a#b"
COMMENT_IN_PARAM = $${a#b}
HASH_IN_FUNCTION = $(shell echo '#')
SHELLY = $(shell printf '%s\n' "$$(date)" | tr a-z A-Z)

# References.
REFS = $(A) ${B} $C $@ $(@D) $(<F) $(SRCS:.c=.o) ${SRCS:%.c=%.o}
DEEP = $(call map,$(patsubst %.c,%.o,$(filter %.c,$(SRCS))))
UNKNOWN_CALL = $(not-a-function arg)
LOWERCASE = $(prefix)/bin $(bindir)
BRACES = ${subst a,b,${X}}
ESCAPED = $$(NOT_A_REFERENCE) $$$(A_REFERENCE)
CONTINUED_CALL = $(foreach f,$(FILES),\
	$(dir $(f)) \
	$(notdir $(f)))
UNTERMINATED = $(oops
AFTER_UNTERMINATED = fine

# Rules.
all: prog lib.a

prog: main.o util.o | builddir
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)
	$(foreach f,$^,\
		echo $(f);)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

.c.o:
	$(CC) $(CFLAGS) -c $<

$(OBJS): %.o: %.c config.h

lib.a:: a.o
lib.a:: b.o

grouped1 grouped2 &: source
	touch grouped1 grouped2

inline: dep ; echo "inline recipe" # shell comment

continued: one \
	two \
	three
	@echo done

prog: CFLAGS += -g
prog: export override PATH := /bin
debug: private DEBUG = 1

all: a .WAIT b

.SECONDEXPANSION:
prog: $$(OBJS) $$@.c

clean:
	-rm -f *.o
	@echo cleaned
	+$(MAKE) -C sub clean
	@-rm -f prog

# Comments, blank lines and conditionals don't end a recipe.
recipe-context:
	echo one
# make comment

	echo two
ifeq ($(V),1)
	echo verbose
else
	echo quiet
endif
	echo three
VAR = ends the recipe
	echo not-a-recipe

# Directives.
include config.mk
-include $(DEPS)
sinclude optional.mk
vpath %.c src
export CC CFLAGS
export PATH = /bin
unexport LDFLAGS
override CFLAGS += -I.
override undefine OLD
private SECRET = 1
undefine STALE
load ./ext.so
-load ./optional.so

ifeq ($(CC),gcc)
  GCC = 1
else ifneq "$(CC)" "clang"
  OTHER = 1
else ifdef FOO
	TAB_INDENTED_ASSIGNMENT = 1
else
endif # comment
ifndef BAR
endif

define TEMPLATE =
$(1): $$($(1)_OBJS)
	$$(CC) -o $$@ $$^
$(1)_CLEAN = rm -f $(1)
endef

define CANNED
echo first
echo "second"
endef

override define OVERRIDDEN
text
	endef in a recipe line does not end the body
endef

$(foreach p,$(PROGRAMS),$(eval $(call TEMPLATE,$(p))))

# A line that isn't recognized mustn't start a "define" that never ends.
!IF "$(TYPE)" == "define"
AFTER_UNRECOGNIZED_DEFINE = 1

# Mistakes.
misindented:
	echo tab-indented
    echo space-indented
    # A comment indented with spaces is fine.
  ifeq ($(V),1)
    $(info so is a function call)
  endif
    VALID_ASSIGNMENT = ends the recipe
space-after-backslash: one \ 
	two
UNTERMINATED_BRACES = ${oops
DEEPLY_NESTED = $(a $(b $(c $(d $(e x)))))
