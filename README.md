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

- **Speed:** Highlighting is 5 to 9 times faster; see the table below.
  Every pattern uses Vim's backtracking regular expression engine and is
  written so that the engine can skip ahead to where it could match. In
  builds of Vim that use musl's memory allocator, the NFA engine's
  allocations made each search an order of magnitude slower.
- **Shell code:** `$$` is treated as an escaped dollar sign, so
  `"$${regex:-^$$}"` is a string containing a parameter expansion that
  contains an escaped `$`, not an unterminated mess. Single- and
  double-quoted strings, backticks, `$$(...)`, `$$((...))`, `$${...}`,
  shell comments and keywords are all recognized. Keywords like `done` are
  only highlighted where a command can start, so `echo done` isn't
  affected. That includes the start of a variable's value and the command
  after a reference like `$(Q)` at the start of a recipe line.
- **Robustness:** An unterminated quote, reference or parenthesis can only
  affect the logical line it's on.
- **Rule context:** A line starting with a tab is only highlighted as a
  recipe line when it follows a rule, which is how Make interprets it.
  Comments, blank lines and conditionals between recipe lines don't end the
  recipe.
- **Variable values:** Values are highlighted as shell code since that's
  how most of them are used. The exception is a function call deferred with
  `$$`, e.g. `$$(error ...)`, when the function's name isn't also a shell
  command or keyword. Comments in values are recognized the way Make
  recognizes them, even inside what looks like a shell string.
- **Templates and canned recipes:** In the body of a `define`, `$$(...)`
  is highlighted as a reference or function call, and `$$@`, `$$<`, `$$^`,
  etc. as automatic variables, since that's what they become when the body
  is evaluated by `$(eval ...)`. The same goes for prerequisites, where
  they're expanded by `.SECONDEXPANSION`, and for the inside of other
  references and function calls. Lines in a `define` that start with a tab
  are highlighted as recipe lines.
- **Errors:** Recipe lines indented with spaces instead of a tab, white
  space after a backslash that was meant to continue a line and references
  that aren't closed by the end of their logical line are highlighted as
  errors.

Time taken to highlight every line of a file in a musl-linked build of Vim
9.1.1868:

| File                          | Lines  | Vim's File | This File |
|-------------------------------|--------|------------|-----------|
| A hand-written POSIX Makefile | 1,205  | 0.36s      | 0.04s     |
| Vim's `src/Makefile`          | 4,779  | 1.01s      | 0.14s     |
| GNU coreutils' `Makefile.in`  | 29,607 | 11.3s      | 2.3s      |

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
| `makeConfig`         | PreCondit    | Autoconf substitutions like `@CC@`¹  |
| `makeConfigIf`       | makeConfig   | `@if NAME` and `@endif NAME` lines¹  |
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
| `makeMisindented`    | Error        | Recipe lines indented with spaces    |
| `makeContError`      | Error        | White space after a backslash        |
| `makeRefError`       | Error        | Unterminated references              |

¹ Only in files with names ending in `.in` or `.am`, which are the ones
configure processes. Elsewhere, text like `@VERSION@` is usually a
placeholder that a recipe replaces.

Items used inside the body of a `define` have a `Def` suffix, e.g.
`makeRecipeDef`, and are linked to the groups without the suffix.

Limitations
-----------

- Microsoft NMAKE's syntax isn't supported, and neither is
  `.RECIPEPREFIX`; recipe lines must start with a tab.
- Outside of a `define`, `$$(...)` in a variable value is highlighted as a
  shell command substitution even when the value is used by `$(eval ...)`,
  unless it's a call to a function like `$$(error ...)` whose name isn't
  also a shell command or keyword. `$$(VAR)`, `$$(eval ...)` and
  `$$(sort ...)` are command substitutions.
- Inside a `define`, `$$(...)` is still a command substitution when it's in
  a `$(shell ...)` call or the word after `case`.
- Unterminated references aren't flagged inside a `define`, where a
  reference can continue onto later lines: telling whether one does would
  take a pattern that looks at later lines, and Vim doesn't highlight a line
  again when a later one changes.
- A backslash at the end of a line always continues the line, even when it's
  escaped by another backslash.
- A continuation line is highlighted as the start of a command when the
  previous line ends with a reference, since references at the end of a line
  like Automake's `$(am__cd) \` usually expand to complete commands.
- After a `;` in a target-specific assignment, GNU Make doesn't treat `#` as
  the start of a comment, but this syntax file does.
- Autoconf's `@if NAME` and `@endif NAME` lines end a variable's value when
  they interrupt one that's continued onto other lines.
- A line with a quote outside of a reference before its first `:` isn't
  recognized as a rule, so that lines like `echo 'Targets:'` in canned
  recipes aren't mistaken for rules.
- References nested more than six levels deep in the names of targets and
  variables keep a line from being recognized as a rule or assignment.

Development
-----------

- `tests/run` highlights each Makefile in `tests` and compares the result
  with the file of the same name with `.out` appended. Run `tests/run -u` to
  update the expected results after reviewing the differences.
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
- Zero-width matches are accepted when they have a `nextgroup`, which can
  be used to start the contents of a region where a command can start.
- Vim only looks for keywords after a character that isn't part of a
  word, so with `-` in `iskeyword`, `-if` doesn't contain the keyword `if`.
- Each time Vim looks for the next match, it checks every pattern against
  what the current item can contain by walking the item's `contains` list
  and, recursively, the clusters in it. Each pattern slows down highlighting
  a little everywhere, and nested clusters slowed it down a lot, so the
  syntax file defines items with `Syn`, which replaces references to
  clusters with the items they stand for.
- A match in a pending `nextgroup` is searched for in the rest of the line,
  so keywords are much faster than matches after operators.
- An end pattern that matches the end of a line makes the item containing
  the region continue onto the next line unless the end pattern is preceded
  by `excludenl`.
- Patterns that fail by backtracking a character at a time, like a name
  that isn't followed by an assignment operator, fail immediately when the
  name is atomic (`\@>`).
- Compiling a regular expression in Vim script, e.g. for `=~#` or
  `substitute()`, is slow, so the template isn't processed a line at a time
  with them.
