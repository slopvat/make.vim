" Usage: vim -N -u NONE -i NONE -n -es -c 'set rtp^=REPOSITORY' \
"          -c 'syntax on' -c 'set syntax=make' \
"          -c 'let g:synspans_out = "OUT"' -S synspans.vim FILE
"
" Write a copy of the buffer to the file named by g:synspans_out in which
" every run of characters highlighted by a syntax group is written as
" "[GROUP:TEXT]". Text outside of any syntax item is written as is. Each line
" is prefixed with its line number.
"
" AI Disclosure:
" - Authorship: Autonomous
" - Models: claude-opus-5-5 (Anthropic)
" - Scope: Written to show how the syntax file highlights a Makefile so the
"   output can be reviewed and used as the expected results of the tests.

function! s:Dump(outfile) abort
  let out = []
  for lnum in range(1, line('$'))
    let line = getline(lnum)
    let text = ''
    let prev = -1
    let run = ''
    for col in range(1, strlen(line) + 1)
      let id = col <= strlen(line) ? synID(lnum, col, 1) : -2
      if id != prev
        if prev != -1
          let name = synIDattr(prev, 'name')
          let text .= empty(name) ? run : '[' . name . ':' . run . ']'
        endif
        let prev = id
        let run = ''
      endif
      if col <= strlen(line)
        let run .= line[col - 1]
      endif
    endfor
    call add(out, printf('%4d %s', lnum, text))
  endfor
  call writefile(out, a:outfile)
endfunction

call s:Dump(g:synspans_out)
qa!
