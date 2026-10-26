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
" Lines in a rule's recipe that are indented with spaces instead of a tab and
" aren't valid Make lines either, which GNU Make reports as a "missing
" separator": they don't start with a directive, comment or function call,
" and they don't have a ":" or "=" outside of a reference. Lines starting
" with Autoconf substitutions are never flagged since there's no telling what
" they'll be replaced with, e.g. "@am__include@" becomes "include".
let s:misindented = ' [ \t]*\%(\%(ifn\=eq\|ifn\=def\|else\|endif'
  \ . '\|-\=include\|sinclude\|export\|unexport\|override\|private'
  \ . '\|undefine\|vpath\|-\=load\|define\|endef\)\>'
  \ . '\|\$[({]\l[a-z-]*[ \t]\|#\)\@!\S\@='
  \ . '\%([^:=#$\\]\|\\.\|\\$\|' . s:ref . '\)\+\%(#.*\)\=$'

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
  \ keepend contains=makeTodo,@makeLineEnd,@Spell
" A backslash that continues a line, or one that was probably meant to but
" is followed by white space. The latter is defined with the shell code so it
" takes priority over shell escapes.
syn cluster makeLineEnd contains=makeLineCont,makeContError
syn match makeLineCont /\%#=1\\$/
syn match makeEscDollar /\%#=1\$\$/
syn match makeConfig /\%#=1@\h\w*@/

" Variable references and function calls -------------------------------------

" Things Make expands wherever they appear.
syn cluster makeExpansions contains=makeRef,makeCall,makeShellCall,
  \makeRefError,makeEscDollar,makeConfig

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
  \ contains=@makeExpansions,@makeLineEnd,makeParens
syn region makeRef matchgroup=makeRef
  \ start=/\%#=1\${/ skip=/\%#=1\\$/ end=/\%#=1}\|$/
  \ contains=@makeExpansions,@makeLineEnd,makeBraces
syn region makeParens contained transparent
  \ start=/\%#=1(/ skip=/\%#=1\\$/ end=/\%#=1)\|$/
syn region makeBraces contained transparent
  \ start=/\%#=1{/ skip=/\%#=1\\$/ end=/\%#=1}\|$/

" In the body of a "define" and in prerequisites, "$$(...)" is a reference
" that's expanded later by "$(eval ...)" or ".SECONDEXPANSION".
syn region makeEscRef contained matchgroup=makeRef
  \ start=/\%#=1\$\$(/ skip=/\%#=1\\$/ end=/\%#=1)\|$/
  \ contains=@makeExpansions,@makeLineEnd,makeParens

" Function calls take on the color of their surroundings, e.g. a recipe's.
" Anything shaped like a call is treated as one, but only the names of GNU
" Make's functions are highlighted: checking for the names in the start
" patterns would slow down every variable reference.
for [s:open, s:close, s:nest] in [['(', ')', 'makeParens'],
                                \ ['{', '}', 'makeBraces']]
  let s:end = 'skip=/\%#=1\\$/ end=/\%#=1' . s:close . '\|$/'
  exe 'syn region makeCall transparent matchgroup=makeRef'
    \ 'start=/\%#=1\$' . s:open . '\ze\l[a-z-]*[ \t]/' s:end
    \ 'contains=makeCallName,@makeExpansions,@makeLineEnd,makePattern,'
    \ . s:nest
  exe 'syn region makeShellCall transparent matchgroup=makeRef'
    \ 'start=/\%#=1\$' . s:open . '\zeshell[ \t]/' s:end
    \ 'contains=makeCallName,@makeShell,' . s:nest
endfor
unlet s:open s:close s:nest s:end
exe 'syn match makeCallName contained'
  \ '/\%#=1\%(\$[({]\)\@2<=\%(' . s:functions . '\)[ \t]\@=/'

" References that aren't closed by the end of their logical line, which is
" checked for up to six levels of nesting. These are defined after the other
" references so they take priority.
for [s:open, s:close] in [['(', ')'], ['{', '}']]
  let s:balanced = '[^' . s:open . s:close . ']*'
  for s:depth in range(5)
    let s:balanced = '\%([^' . s:open . s:close . ']\|\\\n\|'
      \ . s:open . s:balanced . s:close . '\)*'
  endfor
  exe 'syn region makeRefError'
    \ 'start=/\%#=1\$' . s:open . '\%(' . s:balanced . s:close . '\)\@!/'
    \ 'skip=/\%#=1\\$/ end=/\%#=1$/'
endfor
unlet s:open s:close s:balanced s:depth

" Shell code -----------------------------------------------------------------

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
syn region makeShBraces contained transparent start=/\%#=1{/ end=/\%#=1}/
syn region makeShCmdSub contained matchgroup=makeShCmdSubDelim
  \ start=/\%#=1\$\$(/ end=/\%#=1)/ contains=@makeShell,makeShParens
syn region makeShParens contained transparent start=/\%#=1(/ end=/\%#=1)/

" Make still expands variables in shell strings, even single-quoted ones.
syn region makeShSQ contained start=/\%#=1'/ end=/\%#=1'/
  \ contains=@makeExpansions,@makeLineEnd
syn match makeShDQEscape contained /\%#=1\\\%(\$\$\|[\\"`]\)/

" A shell comment ends at the end of the physical line even when Make
" continues the logical line; the shell never sees the backslash-newline.
syn match makeShComment contained /\%#=1#\%([^[:space:];&|()]#\)\@2<!.*/
  \ contains=@makeExpansions,makeTodo,@makeLineEnd
syn match makeShCommentAfterPrefix contained /\%#=1#.*/
  \ contains=@makeExpansions,makeTodo,@makeLineEnd

syn match makeContError /\%#=1\\\s\+$/

" Recipes --------------------------------------------------------------------

" The tab at the start of a recipe line, which is followed by a command and
" optionally prefixes like "@". Continuation lines, which commonly start with
" options like "-o", are excluded.
syn match makeRecipeStart contained transparent
  \ /\%#=1^\%(\\\n\)\@2<!\%(@\h\w*@\)*\t/ contains=makeConfig
  \ nextgroup=makeRecipePrefix,@makeShCommand skipwhite
syn match makeRecipePrefix contained /\%#=1[@+-]\%([ \t]*[@+-]\)*/
  \ nextgroup=makeShCommentAfterPrefix,@makeShCommand skipwhite
exe 'syn match makeMisindented contained /\%#=1^' . s:misindented . '/'

" Directive arguments --------------------------------------------------------

" The arguments of directives, which end at a comment or the end of the
" logical line. Defined before assignments, which take priority after
" "export" and similar keywords.
syn region makeDirArgs contained start=/\%#=1\ze\S/
  \ skip=/\%#=1\\\%([\\#]\|$\)\|\$\%(\$\|[({][^)}#]*#\)/
  \ end=/\%#=1\ze#\|$/ keepend
  \ contains=@makeExpansions,makeEscRef,@makeLineEnd,makePattern,makeString
syn region makeString contained start=/\%#=1"/ end=/\%#=1"/ oneline
  \ contains=@makeExpansions
syn region makeString contained start=/\%#=1'/ end=/\%#=1'/ oneline
  \ contains=@makeExpansions
syn match makeString contained /\%#=1<[^>]*>/ contains=@makeExpansions

syn match makePattern contained /\%#=1%/
syn match makeRuleOp contained /\%#=1:/
syn match makeOrderOnly contained /\%#=1|/
exe 'syn match makeSpecialTarget contained'
  \ '/\%#=1\.\%(\S\.\)\@2<!\%(' . s:special_targets . '\)\>/'

" Rules, assignments and their shell code ------------------------------------

" These items are defined twice: once for most of the Makefile and once, with
" "Def" appended to their names, for the bodies of "define" directives, where
" "$$(...)" is a reference for "$(eval ...)" rather than a command
" substitution. Vim can't make an item behave differently depending on the
" region it's in, so everything that can contain one has a copy.
"
" In the template, "{S}" is replaced with the suffix, "{CONTAINED}" with
" "contained" for the copies of top-level items, "{CMDSUB}" with the group for
" "$$(...)" and the other names in braces with pieces of patterns. Lines
" starting with a backslash continue the previous line.
let s:template =<< trim END
  " Shell syntax outside of strings. Backticks get a separate cluster so a
  " backtick can't start a nested command substitution where it should end
  " one.
  syn cluster makeShWords{S} contains=@makeExpansions,@makeLineEnd,
    \makeShEscape,makeShVar,makeShParam{S},{CMDSUB},makeShSQ,makeShDQ{S},
    \makeShSeparator
  syn cluster makeShell{S} contains=@makeShWords{S},makeShBacktick{S}
  " Shell code that isn't nested in an expansion.
  syn cluster makeShTop{S} contains=@makeShell{S},makeShParenSeparator

  syn region makeShParam{S} contained matchgroup=makeShParam
    \ start=/\%#=1\$\${/ end=/\%#=1}/ contains=@makeShell{S},makeShBraces
  syn region makeShBacktick{S} contained matchgroup=makeShCmdSubDelim
    \ start=/\%#=1`/ skip=/\%#=1\\[\\`]/ end=/\%#=1`/
    \ contains=@makeShWords{S}
  syn region makeShDQ{S} contained start=/\%#=1"/ skip=/\%#=1\\[\\"]/
    \ end=/\%#=1"/ contains=@makeExpansions,@makeLineEnd,makeShDQEscape,
    \makeShVar,makeShParam{S},{CMDSUB},makeShBacktick{S}

  syn region makeRecipe{S} contained start=/\%#=1^\ze\%(@\h\w*@\)*\t/
    \ skip=/\%#=1\\$/ end=/\%#=1$/ keepend
    \ contains=makeRecipeStart,@makeShTop{S},makeShComment

  " A rule's recipe continues until a line that isn't a recipe line,
  " comment, blank line or conditional. Recipe lines can't be recognized by
  " themselves: a line starting with a tab is only a recipe line in the
  " context of a rule.
  syn region makeRecipeBlock{S} contained
    \ start=/\%#=1^\ze\%({INRULE}\|{MISINDENTED}\)/
    \ end=/\%#=1^\%({INRULE}\|{MISINDENTED}\)\@!/
    \ contains=makeRecipe{S},makeMisindented,makeComment,makeConfig,
    \makeConditional,makeBSDConditional

  " Rules are defined before the other kinds of lines, which take priority
  " when they start at the same place.
  syn match makeTarget{S} {CONTAINED} /\%#=1{BOL}{TARGETS}\ze{RULEOP}/
    \ contains=makeSpecialTarget,makePattern,@makeExpansions
    \ nextgroup=makeRuleBody{S} skipwhite
  syn region makeRuleBody{S} contained matchgroup=makeRuleOp
    \ start=/\%#=1&\=::\=/ skip=/\%#=1\\$/ end=/\%#=1$/ keepend
    \ contains=makeSpecialTarget,makePattern,makeRuleOp,makeOrderOnly,
    \@makeExpansions,makeEscRef,@makeLineEnd,makeComment,makeInlineRecipe{S}
    \ nextgroup=makeRecipeBlock{S} skipnl
  syn region makeInlineRecipe{S} contained matchgroup=makeRuleOp
    \ start=/\%#=1;/ skip=/\%#=1\\$/ end=/\%#=1$/ keepend
    \ contains=@makeShTop{S},makeShComment

  " Target-specific variable assignments, e.g. "prog: CFLAGS += -g". They
  " don't start a recipe.
  syn match makeTarget{S} {CONTAINED} /\%#=1{BOL}{TARGETS}\ze{RULEOP}\s*
    \\%(\%(export\|override\|private\|unexport\)\s\+\)*{VAR}{ASSIGN}/
    \ contains=makeSpecialTarget,makePattern,@makeExpansions
    \ nextgroup=makeTargetVarOp{S} skipwhite
  syn match makeTargetVarOp{S} contained /\%#=1&\=::\=/
    \ nextgroup=makeModifier{S},makeVariable{S} skipwhite

  syn match makeVariable{S} {CONTAINED} /\%#=1{BOL}{VAR}\ze{ASSIGN}/
    \ contains=@makeExpansions nextgroup=makeAssignOp{S} skipwhite
  syn match makeVariable{S} contained /\%#=1{VAR}\ze{ASSIGN}/
    \ contains=@makeExpansions nextgroup=makeAssignOp{S} skipwhite
  syn match makeAssignOp{S} contained /\%#=1\%(:::\|::\|[:+?!]\)\==/
    \ nextgroup=makeValue{S} skipwhite
  " Values are highlighted as shell code since that's how most of them end
  " up being used. A "#" outside of a reference starts a comment even in
  " what looks like a shell string, so the value ends there, and the comment
  " is matched by whatever contains the line; Vim ignores regions with
  " zero-width starts like this one if they have a "nextgroup". Since GNU
  " Make 4.3, "#" inside a reference doesn't start a comment, so the skip
  " pattern handles references like "$(shell echo '#')" that don't contain
  " other references.
  "
  " Zero-width regions in a "nextgroup" can start before the white space
  " that "skipwhite" skips, so they start with "\S" to keep from preempting
  " items that follow the white space.
  syn region makeValue{S} contained start=/\%#=1\ze\S/
    \ skip=/\%#=1\\\%([\\#]\|$\)\|\$\%(\$\|[({][^)}#]*#\)/
    \ end=/\%#=1\ze#\|$/ keepend contains=@makeShTop{S}

  syn keyword makeModifier{S} {CONTAINED} export unexport override private
    \ nextgroup=makeModifier{S},makeStatement,makeDirArgs,makeVariable{S},
    \makeDefine skipwhite
END

let s:values = {'BOL': s:bol, 'VAR': s:var, 'ASSIGN': s:assign,
  \ 'TARGETS': s:targets, 'RULEOP': s:ruleop, 'INRULE': s:inrule,
  \ 'MISINDENTED': s:misindented}
for [s:values.S, s:values.CONTAINED, s:values.CMDSUB] in
  \ [['', '', 'makeShCmdSub'], ['Def', 'contained', 'makeEscRef']]
  let s:command = ''
  for s:line in s:template + ['']
    if s:line =~# '^\s*\\'
      let s:command .= substitute(s:line, '^\s*\\', '', '')
      continue
    elseif s:command =~# '\S'
      exe substitute(s:command, '{\(\u\+\)}', '\=s:values[submatch(1)]', 'g')
    endif
    let s:command = s:line =~# '^\s*"' ? '' : s:line
  endfor
endfor
unlet s:template s:values s:command s:line

" Directives -----------------------------------------------------------------

syn keyword makeConditional ifeq ifneq ifdef ifndef
  \ nextgroup=makeDirArgs skipwhite
syn keyword makeConditional else nextgroup=makeConditional skipwhite
syn keyword makeConditional endif
syn keyword makeInclude include -include sinclude
  \ nextgroup=makeDirArgs skipwhite
syn keyword makeStatement vpath undefine load -load
  \ nextgroup=makeDirArgs skipwhite

" BSD directives, which may have whitespace after the ".". They're defined
" after rules so a line like '.if "a:b"' isn't taken for one.
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
  \ end=/\%#=1\ze#\|$/ keepend
  \ contains=@makeExpansions,@makeLineEnd,makeString,makeBSDFunction
syn keyword makeBSDFunction contained defined make empty exists target
  \ commands
syn region makeBSDFor contained start=/\%#=1\ze\S/
  \ skip=/\%#=1\\\%([\\#]\|$\)\|\$\%(\$\|[({][^)}#]*#\)/
  \ end=/\%#=1\ze#\|$/ keepend
  \ contains=@makeExpansions,@makeLineEnd,makeBSDIn
syn keyword makeBSDIn contained in

" Multi-line variables -------------------------------------------------------

syn match makeDefine /\%#=1\<define\>/ nextgroup=makeDefineName skipwhite
exe 'syn match makeDefineName contained /\%#=1' . s:var . '/'
  \ 'contains=@makeExpansions nextgroup=makeDefineOp,makeDefineBody'
  \ 'skipwhite skipnl'
syn match makeDefineOp contained /\%#=1\%(:::\|::\|[:+?!]\)\==/
  \ nextgroup=makeDefineBody skipwhite skipnl
" The body of a "define" is highlighted like the rest of the Makefile, using
" the "Def" copies of items. It starts on the line after "define" since a
" pending "nextgroup" is discarded at the end of a line unless "skipnl" is
" used. A line starting with a tab can't end a "define".
syn region makeDefineBody contained start=/\%#=1^/
  \ matchgroup=makeDefine end=/\%#=1^\%( [ \t]*\)\=endef\>/
  \ contains=@makeExpansions,makeEscRef,makeComment,@makeLineEnd,
  \makeTargetDef,makeVariableDef,makeModifierDef,makeConditional,makeInclude,
  \makeStatement,makeBSDConditional,makeDefine

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
hi def link makeContError Error
hi def link makeDefine Define
hi def link makeDefineName makeVariable
hi def link makeDefineOp makeAssignOp
hi def link makeEscDollar Special
hi def link makeEscRef makeRef
hi def link makeInclude Include
hi def link makeInlineRecipe makeRecipe
hi def link makeLineCont Special
hi def link makeMisindented Error
hi def link makeModifier Statement
hi def link makeOrderOnly makeRuleOp
hi def link makePattern Special
hi def link makeRecipe Number
hi def link makeRecipePrefix Special
hi def link makeRef Identifier
hi def link makeRefError Error
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
hi def link makeTargetVarOp makeRuleOp
hi def link makeTodo Todo
hi def link makeVariable Identifier

for s:group in ['makeAssignOp', 'makeInlineRecipe', 'makeModifier',
              \ 'makeRecipe', 'makeShDQ', 'makeShParam', 'makeTarget',
              \ 'makeTargetVarOp', 'makeVariable']
  exe 'hi def link' s:group . 'Def' s:group
endfor
unlet s:group

let b:current_syntax = "make"

let &cpo = s:cpo_save
unlet s:cpo_save s:bol s:ref s:var s:assign s:targets s:ruleop s:inrule
  \ s:misindented s:functions s:special_targets
