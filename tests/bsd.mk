# AI Disclosure:
# - Authorship: AI-generated
# - Models: claude-opus-5-5 (Anthropic)
# - Scope: Synthetic Makefile exercising BSD make syntax for the tests.

PROG = hello
SRCS = hello.c util.c
OBJS = ${SRCS:.c=.o}
CSRCS = ${SRCS:M*.c}
UPPER = ${PROG:tu}
SUBST = ${SRCS:S/.c/.o/g}
SHELL_OUT != uname -s
OUTFILES = ${TESTS:@test@${.CURDIR}/${test}.out@}

.include <bsd.own.mk>
.include "local.mk"
.-include "optional.mk"
.sinclude "silent.mk"

.if defined(DEBUG) && ${DEBUG} == "yes"
CFLAGS += -g
.elif !empty(SRCS:M*.cc) # comment
CFLAGS += -O2
.  ifndef NESTED
NESTED = 1
.  endif
.else
.endif

.ifdef FOO
.elifndef BAR
.ifmake install
.endif
.endif

.for f in ${SRCS}
${f:R}.o: ${f}
	${CC} ${CFLAGS} -c ${f}
.endfor

.for a b in 1 2 3 4
.endfor

.BEGIN:
	@echo starting
.END:
	@echo finished
.MAIN: all
.PATH: src
.PATH.c: src/c
.ORDER: a b
.NOTPARALLEL:
unexport.out: export.mk

${PROG}: ${OBJS}
	${CC} -o ${.TARGET} ${.ALLSRC}
.if ${MACHINE} == "amd64"
	@echo amd64
.endif
	@echo after the conditional

.undef SUBST
.export PROG
.export-env SRCS
.unexport UPPER
.error "fatal: ${PROG}"
.warning something odd
.info just so you know

# OpenBSD's lazy shell assignments and combined operators.
UID !!= id -u
DATE ?!= date
MORE+!!=uname

.if (${VALUE} < 0)||(${VALUE}>0)
NONZERO = yes
.endif
DIR !?= mktemp -d
OS :sh= uname
SUBDIR_DEPEND_libc++:= libcxxrt
RTTEST_TARGETS+:=rttest${n}
OPTIONAL?:=default
