if exists('g:loaded_clover')
  finish
endif
let g:loaded_clover = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

command! CloverUp call clover#Up()
command! CloverDown call clover#Down()
command! CloverToggle call clover#Toggle()

let &cpoptions = s:save_cpo
unlet s:save_cpo
