make.vim
========

A Vim syntax file for Makefiles written from scratch to replace the one that
ships with Vim. It supports POSIX, GNU and BSD make, and it understands the
shell code inside Makefiles: "$$" escapes, shell strings, variables and
command substitutions are highlighted the way the shell will eventually see
them.

**AI Disclosure:**
- **Authorship:** AI-generated
- **Models:** claude-opus-5-5 (Anthropic)
- **Scope:** Wrote the syntax file, tests, tools and documentation based on
  the user's requirements and answers to design questions.

Differences From Vim's Syntax File
----------------------------------

- **Speed:** Highlighting is roughly 10 times faster. Every pattern uses
  Vim's backtracking regular expression engine and is written so that the
  engine can skip ahead to where it could match. In builds of Vim that use
  musl's memory allocator, the NFA engine's allocations made each search an
  order of magnitude slower.
- **Shell code:** `$$` is treated as an escaped dollar sign, so
  `"$${regex:-^$$}"` is a string containing a parameter expansion that
  contains an escaped `$`, not an unterminated mess. Single- and
  double-quoted strings, backticks, `$$(...)`, `$${...}`, shell comments and
  keywords are all recognized. Keywords like `done` are only highlighted
  where a command can start, so `echo done` isn't affected.
- **Robustness:** An unterminated quote, reference or parenthesis can only
  affect the logical line it's on.
- **Rule context:** A line starting with a tab is only highlighted as a
  recipe line when it follows a rule, which is how Make interprets it.
  Comments, blank lines and conditionals between recipe lines don't end the
  recipe.

Installation
------------

Copy or symlink `syntax/make.vim` to `~/.vim/syntax/make.vim`, or add this
repository to the `runtimepath`, e.g. by cloning it to
`~/.vim/pack/plugins/start/make.vim`. Files in `~/.vim/syntax` are loaded
before Vim's own, which then stops loading because `b:current_syntax` is set.

The syntax file sets `syntax sync fromstart` since the meaning of a line
depends on the lines before it.

Highlighting Groups
-------------------

| Group                | Default Link | Highlights                           |
|----------------------|--------------|--------------------------------------|
| `makeTarget`         | Function     | Targets of rules                     |
| `makeSpecialTarget`  | Statement    | `.PHONY`, `.SUFFIXES`, `.BEGIN`, ... |
| `makeRuleOp`         | Operator     | `:`, `::`, `&:` and `;` in rules     |
| `makeOrderOnly`      | makeRuleOp   | The `\|` before order-only prereqs   |
| `makePattern`        | Special      | `%` in patterns                      |
| `makeVariable`       | Identifier   | Variables being assigned             |
| `makeAssignOp`       | Operator     | `=`, `:=`, `::=`, `+=`, `?=`, ...    |
| `makeRef`            | Identifier   | `$(VAR)`, `${VAR}` and `$@`          |
| `makeCallName`       | Function     | Names of GNU Make functions          |
| `makeEscDollar`      | Special      | `$$` not followed by a shell name    |
| `makeLineCont`       | Special      | Backslashes that continue lines      |
| `makeConfig`         | PreCondit    | Autoconf substitutions like `@CC@`   |
| `makeComment`        | Comment      | Make comments                        |
| `makeConditional`    | PreCondit    | `ifeq`, `.if`, `.for`, ...           |
| `makeInclude`        | Include      | `include`, `.include`, ...           |
| `makeStatement`      | Statement    | `vpath`, `undefine`, `.error`, ...   |
| `makeModifier`       | Statement    | `export`, `override`, ...            |
| `makeDefine`         | Define       | `define` and `endef`                 |
| `makeString`         | String       | Strings in directives                |
| `makeBSDFunction`    | Function     | `defined`, `empty`, ... in `.if`     |
| `makeRecipe`         | Number       | Recipes                              |
| `makeRecipePrefix`   | Special      | `@`, `-` and `+` before commands     |
| `makeShSQ`           | String       | Single-quoted shell strings          |
| `makeShDQ`           | String       | Double-quoted shell strings          |
| `makeShVar`          | PreProc      | `$$name`, `$$1`, `$$?`, ...          |
| `makeShParam`        | PreProc      | `$${name:-default}`                  |
| `makeShCmdSubDelim`  | Special      | Delimiters of `$$(...)` and backticks |
| `makeShEscape`       | Special      | Backslash escapes                    |
| `makeShConditional`  | Conditional  | `if`, `then`, `case`, ...            |
| `makeShRepeat`       | Repeat       | `for`, `while`, `do`, ...            |
| `makeShComment`      | Comment      | Shell comments in recipes            |

Development
-----------

- `tests/run` highlights each Makefile in `tests` and compares the result
  with the matching `.out` file. Run `tests/run -u` to update the expected
  results after reviewing the differences.
- `tools/synspans.vim` writes a copy of a buffer that shows the syntax group
  of every run of text. It's what `tests/run` uses.
- `tools/benchmark.vim` prints how long it takes to highlight a file.

Syntax items in this file follow a few rules discovered while writing it:

- Patterns start with `\%#=1` to use the backtracking engine, and they start
  with a literal character or `^` when possible since the engine tries a
  leading lookbehind or character class at every column.
- Regions whose delimiters could be matched by contained items use
  `matchgroup`; otherwise, contained items are matched inside the start and
  end patterns and can keep a region from ending.
- Regions with zero-width starts are ignored if they have a `nextgroup`, and
  in a `nextgroup` they start before the white space that `skipwhite` skips.
- A skip pattern that matches up to the end of a line makes a region
  continue onto the next line.
