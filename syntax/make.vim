" Vim syntax file
" Language: Make (POSIX, GNU and BSD)
"
" Highlights Makefiles with an understanding of the shell code they contain:
" "$$" escapes, shell strings, variables and command substitutions are
" highlighted the way the shell will eventually see them, and an unterminated
" quote or parenthesis can only affect the logical line it appears on.
"
" AI Disclosure:
" - Authorship: AI-generated
" - Models: claude-opus-5-5 (Anthropic)
" - Scope: Wrote the syntax file from scratch based on the user's requirements
"   and answers to design questions.
" - References:
"   - ~/.local/bin/vimruntime/syntax/make.vim (Vim's syntax file, consulted
"     for the constructs it supports)
"
" Every pattern starts with "\%#=1" to select the backtracking regular
" expression engine. The NFA engine allocates memory for each search, and in
" Vim builds that use an allocator like musl's, that made each search an
" order of magnitude slower. Patterns also start with a literal character or
" "^" whenever possible: the backtracking engine skips ahead to the first
" occurrence of a leading literal and only tries patterns starting with "^" at
" the start of a line, but it tries a leading lookbehind at every column.

if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

" Lets "-include", "-load" and "filter-out" be matched as keywords and keeps
" shell keywords from matching inside words like "clean-if".
syn iskeyword @,48-57,_,192-255,-

" Pieces of patterns used to recognize the different kinds of lines. All of
" them begin at the start of a line, optionally after Autoconf or Automake
" substitutions like "@am__fastdepCC_TRUE@". The substitutions are part of
" the match rather than being skipped with "\zs": after an item that starts
" earlier on the line, Vim searches for the next match from where that item
" ended, and a pattern starting with "^" can't match there.
let s:bol = '^\%(\%(@\h\w*@\)\+\s*\|\s*\zs\)'
" A variable reference with up to three levels of nesting.
let s:ref = '\$\%((\%([^()]\|(\%([^()]\|([^()]*)\)*)\)*)'
  \ . '\|{\%([^{}]\|{\%([^{}]\|{[^{}]*}\)*}\)*}\|[^({]\)'
" The name of a variable being assigned. "+", "?" and "!" are allowed in
" names, but not right before "=" where they're part of the operator.
let s:var = '\%([^[:space:]:#=$+?!]\|[+?!]=\@!\|' . s:ref . '\)\+'
let s:assign = '\s*\%(:::\|::\|[:+?!]\)\=='
" The targets of a rule and the rule operator that follows them.
let s:targets = '\%([^[:space:]:#=$&]\|&:\@!\|' . s:ref . '\)'
  \ . '\%([^:#=$&]\|&:\@!\|' . s:ref . '\)*'
let s:ruleop = '\s*&\=::\=[:=]\@!'
" Lines that keep a rule's recipe going: recipe lines, comments, blank lines
" and conditionals.
let s:inrule = '\%(@\h\w*@\)*\%(\t\|[ \t]*\%(#\|$\)\)'
  \ . '\|[ \t]*\%(ifn\=eq\|ifn\=def\|else\|endif\)\>'
  \ . '\|\.\s*\%(\%(el\)\=if\|else\>\|endif\>\|for\>\|endfor\>\)'

let s:functions = join([
  \ 'abspath', 'addprefix', 'addsuffix', 'and', 'basename', 'call', 'dir',
  \ 'error', 'eval', 'file', 'filter', 'filter-out', 'findstring',
  \ 'firstword', 'flavor', 'foreach', 'guile', 'if', 'info', 'intcmp', 'join',
  \ 'lastword', 'let', 'notdir', 'or', 'origin', 'patsubst', 'realpath',
  \ 'shell', 'sort', 'strip', 'subst', 'suffix', 'value', 'warning',
  \ 'wildcard', 'word', 'wordlist', 'words'
  \ ], '\|')

let s:special_targets = join([
  \ 'BEGIN', 'DEFAULT', 'DELETE_ON_ERROR', 'END', 'ERROR', 'EXEC',
  \ 'EXPORT_ALL_VARIABLES', 'IGNORE', 'INCLUDES', 'INTERMEDIATE', 'INTERRUPT',
  \ 'JOIN', 'LIBS', 'LOW_RESOLUTION_TIME', 'MADE', 'MAIN', 'MAKE',
  \ 'MAKEFLAGS', 'META', 'MFLAGS', 'NOMETA', 'NOMETA_CMP', 'NOPATH',
  \ 'NOREADONLY', 'NOTINTERMEDIATE', 'NOTMAIN', 'NOTPARALLEL', 'NO_PARALLEL',
  \ 'NULL', 'OBJDIR', 'ONESHELL', 'OPTIONAL', 'ORDER', 'PATH\%(\.\S*\)\=',
  \ 'PHONY', 'POSIX', 'PRECIOUS', 'READONLY', 'SCCS_GET', 'SECONDARY',
  \ 'SECONDEXPANSION', 'SHELL', 'SILENT', 'STALE', 'SUFFIXES', 'USE',
  \ 'USEBEFORE', 'WAIT'
  \ ], '\|')

" Comments, escapes and substitutions ----------------------------------------

syn keyword makeTodo contained TODO FIXME XXX
" A comment, which a trailing backslash continues onto the next line.
syn region makeComment start=/\%#=1#/ skip=/\%#=1\\$/ end=/\%#=1$/
  \ keepend contains=makeTodo,makeLineCont,@Spell
syn match makeLineCont /\%#=1\\$/
syn match makeEscDollar /\%#=1\$\$/
syn match makeConfig /\%#=1@\h\w*@/

" Variable references and function calls -------------------------------------

" Things Make expands wherever they appear.
syn cluster makeExpansions
  \ contains=makeRef,makeCall,makeShellCall,makeEscDollar,makeConfig

" Make counts nested parentheses (or braces) in a reference without regard to
" shell quoting, so references contain transparent regions that do the same.
" References never extend past the end of a logical line.
"
" Regions whose delimiters could be mistaken for contained items use
" "matchgroup" since contained items are otherwise also matched inside the
" text of the start and end patterns.
syn match makeRef /\%#=1\$[^({$]/
syn region makeRef matchgroup=makeRef
  \ start=/\%#=1\$(/ skip=/\%#=1\\$/ end=/\%#=1)\|$/
  \ contains=@makeExpansions,makeLineCont,makeParens
syn region makeRef matchgroup=makeRef
  \ start=/\%#=1\${/ skip=/\%#=1\\$/ end=/\%#=1}\|$/
  \ contains=@makeExpansions,makeLineCont,makeBraces
syn region makeParens contained transparent
  \ start=/\%#=1(/ skip=/\%#=1\\$/ end=/\%#=1)\|$/
syn region makeBraces contained transparent
  \ start=/\%#=1{/ skip=/\%#=1\\$/ end=/\%#=1}\|$/

" Function calls take on the color of their surroundings, e.g. a recipe's.
" Anything shaped like a call is treated as one, but only the names of GNU
" Make's functions are highlighted: checking for the names in the start
" patterns would slow down every variable reference.
for [s:open, s:close, s:nest] in [['(', ')', 'makeParens'],
                                \ ['{', '}', 'makeBraces']]
  let s:end = 'skip=/\%#=1\\$/ end=/\%#=1' . s:close . '\|$/'
  exe 'syn region makeCall transparent matchgroup=makeRef'
    \ 'start=/\%#=1\$' . s:open . '\ze\l[a-z-]*[ \t]/' s:end
    \ 'contains=makeCallName,@makeExpansions,makeLineCont,makePattern,'
    \ . s:nest
  exe 'syn region makeShellCall transparent matchgroup=makeRef'
    \ 'start=/\%#=1\$' . s:open . '\zeshell[ \t]/' s:end
    \ 'contains=makeCallName,@makeShell,' . s:nest
endfor
unlet s:open s:close s:nest s:end
exe 'syn match makeCallName contained'
  \ '/\%#=1\%(\$[({]\)\@2<=\%(' . s:functions . '\)[ \t]\@=/'

" Shell code -----------------------------------------------------------------

" Shell syntax outside of strings. Backticks get a separate cluster so a
" backtick can't start a nested command substitution where it should end one.
syn cluster makeShWords contains=@makeExpansions,makeLineCont,makeShEscape,
  \makeShVar,makeShParam,makeShCmdSub,makeShSQ,makeShDQ,makeShSeparator
syn cluster makeShell contains=@makeShWords,makeShBacktick
" Shell code that isn't nested in an expansion.
syn cluster makeShTop contains=@makeShell,makeShParenSeparator

" Keywords are only recognized where a command can start, so "echo done"
" doesn't highlight "done". That's after an operator, after a keyword that
" precedes a command, at the start of a recipe line and at the start of a
" continuation line when the previous line ended with one of those.
"
" Parentheses only count as operators outside of command substitutions since
" contained items would otherwise preempt the closing parentheses of the
" regions that track nesting.
syn cluster makeShCommand
  \ contains=makeShConditional,makeShRepeat,makeShCommandLineCont
syn match makeShSeparator contained transparent /\%#=1[;&|{]/
  \ nextgroup=@makeShCommand skipwhite
syn match makeShParenSeparator contained transparent /\%#=1[()]/
  \ nextgroup=@makeShCommand skipwhite
syn match makeShCommandLineCont contained /\%#=1\\$/
  \ nextgroup=@makeShCommand skipwhite skipnl
syn keyword makeShConditional contained if then else elif
  \ nextgroup=@makeShCommand skipwhite
syn keyword makeShConditional contained fi esac
syn keyword makeShConditional contained case nextgroup=makeShCaseWord skipwhite
syn keyword makeShRepeat contained while until do
  \ nextgroup=@makeShCommand skipwhite
syn keyword makeShRepeat contained done
syn keyword makeShRepeat contained for nextgroup=makeShForName skipwhite
syn match makeShForName contained transparent /\%#=1\h\w*/
  \ nextgroup=makeShIn skipwhite
syn match makeShCaseWord contained transparent /\%#=1\S\+/
  \ contains=@makeShWords nextgroup=makeShIn skipwhite
syn keyword makeShIn contained in

" A backslash before "$$" escapes the dollar sign the shell will see; before
" "$(...)" it escapes the first character of the expansion, not the "$".
syn match makeShEscape contained /\%#=1\\\%(\$\$\|[^$]\)/
syn match makeShVar contained /\%#=1\$\$\%(\$\$\|[@*#?!0-9-]\|\h\w*\)/
syn region makeShParam contained matchgroup=makeShParam
  \ start=/\%#=1\$\${/ end=/\%#=1}/ contains=@makeShell,makeShBraces
syn region makeShBraces contained transparent start=/\%#=1{/ end=/\%#=1}/
syn region makeShCmdSub contained matchgroup=makeShCmdSubDelim
  \ start=/\%#=1\$\$(/ end=/\%#=1)/ contains=@makeShell,makeShParens
syn region makeShParens contained transparent start=/\%#=1(/ end=/\%#=1)/
syn region makeShBacktick contained matchgroup=makeShCmdSubDelim
  \ start=/\%#=1`/ skip=/\%#=1\\[\\`]/ end=/\%#=1`/ contains=@makeShWords

" Make still expands variables in shell strings, even single-quoted ones.
syn region makeShSQ contained start=/\%#=1'/ end=/\%#=1'/
  \ contains=@makeExpansions,makeLineCont
syn region makeShDQ contained start=/\%#=1"/ skip=/\%#=1\\[\\"]/
  \ end=/\%#=1"/ contains=@makeExpansions,makeLineCont,makeShDQEscape,
  \makeShVar,makeShParam,makeShCmdSub,makeShBacktick
syn match makeShDQEscape contained /\%#=1\\\%(\$\$\|[\\"`]\)/

" A shell comment ends at the end of the physical line even when Make
" continues the logical line; the shell never sees the backslash-newline.
syn match makeShComment contained /\%#=1#\%([^[:space:];&|()]#\)\@2<!.*/
  \ contains=@makeExpansions,makeTodo,makeLineCont
syn match makeShCommentAfterPrefix contained /\%#=1#.*/
  \ contains=@makeExpansions,makeTodo,makeLineCont

" Recipes --------------------------------------------------------------------

" The tab at the start of a recipe line, which is followed by a command and
" optionally prefixes like "@". Continuation lines, which commonly start with
" options like "-o", are excluded.
syn match makeRecipeStart contained transparent
  \ /\%#=1^\%(\\\n\)\@2<!\%(@\h\w*@\)*\t/ contains=makeConfig
  \ nextgroup=makeRecipePrefix,@makeShCommand skipwhite
syn match makeRecipePrefix contained /\%#=1[@+-]\%([ \t]*[@+-]\)*/
  \ nextgroup=makeShCommentAfterPrefix,@makeShCommand skipwhite
syn region makeRecipe contained start=/\%#=1^\ze\%(@\h\w*@\)*\t/
  \ skip=/\%#=1\\$/ end=/\%#=1$/ keepend
  \ contains=makeRecipeStart,@makeShTop,makeShComment

" A rule's recipe continues until a line that isn't a recipe line, comment,
" blank line or conditional. Recipe lines can't be recognized by themselves:
" a line starting with a tab is only a recipe line in the context of a rule.
exe 'syn region makeRecipeBlock contained'
  \ 'start=/\%#=1^\ze\%(' . s:inrule . '\)/'
  \ 'end=/\%#=1^\%(' . s:inrule . '\)\@!/'
  \ 'contains=makeRecipe,makeComment,makeConfig,makeConditional,'
  \ . 'makeBSDConditional'

" Directive arguments --------------------------------------------------------

" The arguments of directives, which end at a comment or the end of the
" logical line. Defined before assignments, which take priority after
" "export" and similar keywords.
syn region makeDirArgs contained start=/\%#=1\ze\S/
  \ skip=/\%#=1\\\%([\\#]\|$\)\|\$\%(\$\|[({][^)}#]*#\)/
  \ end=/\%#=1\ze#\|$/
  \ keepend contains=@makeExpansions,makeLineCont,makePattern,makeString
syn region makeString contained start=/\%#=1"/ end=/\%#=1"/ oneline
  \ contains=@makeExpansions
syn region makeString contained start=/\%#=1'/ end=/\%#=1'/ oneline
  \ contains=@makeExpansions
syn match makeString contained /\%#=1<[^>]*>/ contains=@makeExpansions

" Rules ----------------------------------------------------------------------

" Defined before the patterns for other kinds of lines, which take priority
" when they start at the same place.
exe 'syn match makeTarget /\%#=1' . s:bol . s:targets
  \ . '\ze' . s:ruleop . '/'
  \ 'contains=makeSpecialTarget,makePattern,@makeExpansions'
  \ 'nextgroup=makeRuleBody skipwhite'
syn region makeRuleBody contained matchgroup=makeRuleOp
  \ start=/\%#=1&\=::\=/ skip=/\%#=1\\$/ end=/\%#=1$/ keepend
  \ contains=makeSpecialTarget,makePattern,makeRuleOp,makeOrderOnly,
  \@makeExpansions,makeLineCont,makeComment,makeInlineRecipe
  \ nextgroup=makeRecipeBlock skipnl
exe 'syn match makeSpecialTarget contained'
  \ '/\%#=1\.\%(\S\.\)\@2<!\%(' . s:special_targets . '\)\>/'
syn match makePattern contained /\%#=1%/
syn match makeRuleOp contained /\%#=1:/
syn match makeOrderOnly contained /\%#=1|/
syn region makeInlineRecipe contained matchgroup=makeRuleOp start=/\%#=1;/
  \ skip=/\%#=1\\$/ end=/\%#=1$/ keepend
  \ contains=@makeShTop,makeShComment

" Target-specific variable assignments, e.g. "prog: CFLAGS += -g". They don't
" start a recipe.
exe 'syn match makeTarget /\%#=1' . s:bol . s:targets
  \ . '\ze' . s:ruleop . '\s*'
  \ . '\%(\%(export\|override\|private\|unexport\)\s\+\)*' . s:var . s:assign
  \ . '/ contains=makeSpecialTarget,makePattern,@makeExpansions'
  \ 'nextgroup=makeTargetVarOp skipwhite'
syn match makeTargetVarOp contained /\%#=1&\=::\=/
  \ nextgroup=makeModifier,makeVariable skipwhite

" Variable assignments -------------------------------------------------------

exe 'syn match makeVariable /\%#=1' . s:bol . s:var
  \ . '\ze' . s:assign . '/'
  \ 'contains=@makeExpansions nextgroup=makeAssignOp skipwhite'
exe 'syn match makeVariable contained /\%#=1' . s:var . '\ze' . s:assign . '/'
  \ 'contains=@makeExpansions nextgroup=makeAssignOp skipwhite'
syn match makeAssignOp contained /\%#=1\%(:::\|::\|[:+?!]\)\==/
  \ nextgroup=makeValue skipwhite
" Values are highlighted as shell code since that's how most of them end up
" being used. A "#" outside of a reference starts a comment even in what
" looks like a shell string, so the value ends there, and the comment is
" matched by whatever contains the line; Vim ignores regions with zero-width
" starts like this one if they have a "nextgroup". Since GNU Make 4.3, "#"
" inside a reference doesn't start a comment, so the skip pattern handles
" references like "$(shell echo '#')" that don't contain other references.
"
" Zero-width regions in a "nextgroup" can start before the white space that
" "skipwhite" skips, so they start with "\S" to keep from preempting items
" that follow the white space.
syn region makeValue contained start=/\%#=1\ze\S/
  \ skip=/\%#=1\\\%([\\#]\|$\)\|\$\%(\$\|[({][^)}#]*#\)/
  \ end=/\%#=1\ze#\|$/
  \ keepend contains=@makeShTop

" Directives -----------------------------------------------------------------

syn keyword makeConditional ifeq ifneq ifdef ifndef
  \ nextgroup=makeDirArgs skipwhite
syn keyword makeConditional else nextgroup=makeConditional skipwhite
syn keyword makeConditional endif
syn keyword makeInclude include -include sinclude
  \ nextgroup=makeDirArgs skipwhite
syn keyword makeStatement vpath undefine load -load
  \ nextgroup=makeDirArgs skipwhite
syn keyword makeModifier export unexport override private
  \ nextgroup=makeModifier,makeStatement,makeDirArgs,makeVariable,makeDefine
  \ skipwhite

" BSD directives, which may have whitespace after the ".".
syn match makeBSDConditional
  \ /\%#=1^\.\s*\%(el\)\=if\%(n\=def\|n\=make\)\=\>/
  \ nextgroup=makeBSDExpr skipwhite
syn match makeBSDConditional /\%#=1^\.\s*\%(else\|endif\|endfor\)\>/
syn match makeBSDConditional /\%#=1^\.\s*for\>/
  \ nextgroup=makeBSDFor skipwhite
syn match makeInclude /\%#=1^\.\s*[-sd]\=include\>/
  \ nextgroup=makeDirArgs skipwhite
exe 'syn match makeStatement /\%#=1^\.\s*\%(' . join([
  \ 'break', 'error', 'export', 'export-all', 'export-env', 'export-literal',
  \ 'info', 'poison', 'undef', 'unexport', 'unexport-env', 'warning'
  \ ], '\|') . '\)\>/ nextgroup=makeDirArgs skipwhite'

syn region makeBSDExpr contained start=/\%#=1\ze\S/
  \ skip=/\%#=1\\\%([\\#]\|$\)\|\$\%(\$\|[({][^)}#]*#\)/
  \ end=/\%#=1\ze#\|$/
  \ keepend contains=@makeExpansions,makeLineCont,makeString,makeBSDFunction
syn keyword makeBSDFunction contained defined make empty exists target
  \ commands
syn region makeBSDFor contained start=/\%#=1\ze\S/
  \ skip=/\%#=1\\\%([\\#]\|$\)\|\$\%(\$\|[({][^)}#]*#\)/
  \ end=/\%#=1\ze#\|$/
  \ keepend contains=@makeExpansions,makeLineCont,makeBSDIn
syn keyword makeBSDIn contained in

" Multi-line variables -------------------------------------------------------

" The body of a "define" is highlighted like the rest of the Makefile since
" it is often a template for "$(eval ...)".
syn match makeDefine /\%#=1\<define\>/ nextgroup=makeDefineName skipwhite
exe 'syn match makeDefineName contained /\%#=1' . s:var . '/'
  \ 'contains=@makeExpansions nextgroup=makeDefineOp,makeDefineBody'
  \ 'skipwhite skipnl'
syn match makeDefineOp contained /\%#=1\%(:::\|::\|[:+?!]\)\==/
  \ nextgroup=makeDefineBody skipwhite skipnl
" The body starts on the line after "define" since a pending "nextgroup" is
" discarded at the end of a line unless "skipnl" is used. A line starting with
" a tab can't end a "define".
syn region makeDefineBody contained start=/\%#=1^/
  \ matchgroup=makeDefine end=/\%#=1^\%( [ \t]*\)\=endef\>/ contains=TOP

" Synchronization ------------------------------------------------------------

syn sync fromstart

" Highlighting ---------------------------------------------------------------

hi def link makeAssignOp Operator
hi def link makeBSDConditional makeConditional
hi def link makeBSDFunction Function
hi def link makeBSDIn makeConditional
hi def link makeCallName Function
hi def link makeComment Comment
hi def link makeConditional PreCondit
hi def link makeConfig PreCondit
hi def link makeDefine Define
hi def link makeDefineName makeVariable
hi def link makeDefineOp makeAssignOp
hi def link makeEscDollar Special
hi def link makeInclude Include
hi def link makeInlineRecipe makeRecipe
hi def link makeLineCont Special
hi def link makeModifier Statement
hi def link makeOrderOnly makeRuleOp
hi def link makePattern Special
hi def link makeRecipe Number
hi def link makeRecipePrefix Special
hi def link makeRef Identifier
hi def link makeRuleOp Operator
hi def link makeShComment Comment
hi def link makeShCommentAfterPrefix makeShComment
hi def link makeShCmdSubDelim Special
hi def link makeShConditional Conditional
hi def link makeShDQ String
hi def link makeShDQEscape Special
hi def link makeShEscape Special
hi def link makeShIn Statement
hi def link makeShParam PreProc
hi def link makeShRepeat Repeat
hi def link makeShSQ String
hi def link makeShVar PreProc
hi def link makeSpecialTarget Statement
hi def link makeStatement Statement
hi def link makeString String
hi def link makeTarget Function
hi def link makeTodo Todo
hi def link makeVariable Identifier

let b:current_syntax = "make"

let &cpo = s:cpo_save
unlet s:cpo_save s:bol s:ref s:var s:assign s:targets s:ruleop s:inrule
  \ s:functions s:special_targets
