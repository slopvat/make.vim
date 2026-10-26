# AI Disclosure:
# - Authorship: AI-generated
# - Models: claude-opus-5-5 (Anthropic)
# - Scope: Synthetic Makefile exercising shell code in recipes for the tests.

strings:
	echo "double $(MAKE_VAR) $$shell_var $${param:-default} $$(date) `uname`"
	echo 'single $(MAKE_VAR) $$not_a_shell_var'
	echo "escaped \"quotes\" and \$$dollar and \\ backslash"
	echo \"not a string\" \'neither\'
	echo "unterminated
	echo "the line above doesn't affect this one"
	echo 'multi-line \
	string'
	echo "multi-line \
	string"

dollars:
	echo $$HOME $$1 $$@ $$? $$$$ $$# $$-
	echo $${name} $${name:-word} $${name%%/*} $${name#prefix} $${#name}
	echo $${outer:-$${inner}} $${x:-"}"}
	grep -qe "$${last_patch_regex:-^$$}"
	last_patch_regex='-0*$(BASH_PATCH_LEVEL)$$'
	awk '{ print $$1 }'
	echo $$$(MAKE_VAR) $$
	echo $$((1 + 2)) $$(echo $$(nested))

keywords:
	if [ -e /etc/debian_version ]; then \
		echo debian; \
	elif [ "$$(uname)" = Darwin ]; then \
		echo macos; \
	else \
		echo done; \
	fi
	for path in $(FILES); do \
		case "$$path" in \
		  *.c|*.h) echo source ;; \
		  *) continue ;; \
		esac; \
	done
	while read -r line; do echo "$$line"; done < input
	until false; do break; done
	if ! $(MAKE) -k; then (cd sub && $(MAKE)) fi
	test -n "$(V)" && if true; then echo if; fi
	@if true; then :; fi
	echo if then else fi for in do done case esac while until

comments:
	# A shell comment with $(MAKE_VAR) expanded by Make. TODO: noted.
	@# A silent shell comment.
	echo not#a#comment ${not_a_comment#x} # but this is
	echo "# not a comment" '# nor this'
	echo continued \
	# comment on a continuation line \
	echo after the comment

escapes:
	find . -name '*.o' -exec rm {} \;
	echo \$$HOME \$(MAKE_VAR)
	printf '%s\n' a\ b

prefixes:
	@echo silent
	-rm -f maybe
	+$(MAKE) always
	@-+echo all three
	 @echo space after the tab
	cc -o prog \
		-O2 \
		-Wall
