if exists('g:autoloaded_clover')
  finish
endif
let g:autoloaded_clover = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

if !hlexists('CloverCovered')
  highlight def cloverCovered guifg='Green' ctermfg=Green
endif

if !hlexists('CloverUncovered')
  highlight def cloverUncovered guifg='Red' ctermfg=Red
endif

if !hlexists('CloverIgnored')
  highlight def CloverIgnored guifg='Gray' ctermfg=Gray
endif

" For now, this highlights every single line in the current file
function! clover#Up() abort
  let b:toggled = 1

  let l:matches = []

  let l:count = 1
  while l:count <= line('$')
    call add(matches, {'group': 'CloverCovered', 'pos': [l:count]})
    let l:count += 1
  endwhile

  augroup clover_cleanup
    autocmd! * <buffer>
    autocmd BufWinLeave <buffer> call clover#down()
  augroup end

  for l:m in matches
    call matchaddpos(l:m.group, l:m.pos)
  endfor
endfunction

" Clear all coverage highlights.
function! clover#Down() abort
  call clearmatches()

  let b:toggled = 0

  augroup clover_cleanup
    autocmd! * <buffer>
  augroup end
endfunction

function! clover#Toggle() abort
  if exists('b:toggled') && b:toggled
    call clover#Down()
  else
    call clover#Up()
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
