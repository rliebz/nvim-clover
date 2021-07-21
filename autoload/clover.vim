if exists('g:autoloaded_clover')
  finish
endif
let g:autoloaded_clover = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

highlight default CloverCovered guifg=Green ctermfg=Green
highlight default CloverUncovered guifg=Red ctermfg=Red
highlight default CloverIgnored guifg=Gray ctermfg=Gray

function! clover#Up() abort
  if &filetype ==# 'go'
    call clover#go#Up()
  elseif index(['javascript', 'javascriptreact', 'typescript', 'typescriptreact'], &filetype != -1)
    " TODO: Jest is not a safe assumption
    lua require('clover.jest').jest_up()
  else
    echoerr 'Unsupported file type: ' . &filetype
  endif
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
