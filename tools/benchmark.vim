" Usage: vim -N -u NONE -i NONE -n -es -c 'set rtp^=REPOSITORY' \
"          -c 'syntax on' -c 'set syntax=make' -S benchmark.vim FILE
"
" Print how long it takes to highlight every line of the buffer, which is
" what jumping to the end of the file costs with "syntax sync fromstart".
"
" AI Disclosure:
" - Authorship: Autonomous
" - Models: claude-opus-5-5 (Anthropic)
" - Scope: Written to measure the performance of the syntax file while
"   optimizing it.

let s:name = expand('%:t')
let s:lines = line('$')
let s:start = reltime()
for s:lnum in range(1, s:lines)
  call synID(s:lnum, 1, 0)
endfor
let s:elapsed = reltimefloat(reltime(s:start))
" In Ex mode, ":print" writes to stdout but ":echo" doesn't.
enew
call setline(1, printf('%s: %d lines in %.3f seconds', s:name, s:lines,
  \ s:elapsed))
print
qa!
