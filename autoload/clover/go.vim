function! clover#go#Up() abort
  let l:tempname = tempname()

  let l:job_opts = {}
  let l:job_opts.cwd = expand('%:h')
  let l:job_opts.on_exit = function('s:OnJobExit', [l:tempname])

  let l:cmd_args = ['-coverprofile', l:tempname]

  " Integration with vim-test/vim-test
  if g:loaded_test
    let l:cmd_args = test#base#options('go#gotest', l:cmd_args)
    let l:cmd_args = test#base#options('go#gotest', l:cmd_args, 'suite')
  endif

  let l:cmd = ['go', 'test'] + l:cmd_args
  let l:job = jobstart(l:cmd, l:job_opts)
endfunction

function! s:OnJobExit(coverfile, job_id, data, event) abort
  if !filereadable(a:coverfile)
    return
  endif

  let b:toggled = 1

  let l:matches = []

  let l:count = 1
  while l:count <= line('$')
    call add(l:matches, {'group': 'CloverIgnored', 'pos': [l:count]})
    let l:count += 1
  endwhile

  let l:filename = expand('%:t')

  let l:lines = readfile(a:coverfile)
  for l:line in l:lines[1:]
    let l:cov = s:ParseLine(line)

    if l:filename != fnamemodify(l:cov.file, ':t')
      continue
    endif

    call add(l:matches, s:GetMatchForLine(cov))
  endfor

  augroup clover_cleanup
    autocmd! * <buffer>
    autocmd BufModifiedSet,BufWinLeave <buffer> call clover#Down()
  augroup end

  for l:m in l:matches
    call matchaddpos(l:m.group, l:m.pos)
  endfor

  call delete(a:coverfile)
endfunction

function! s:GetMatchForLine(cov) abort
  let l:group = 'CloverCovered'
  if a:cov.count == 0
    let l:group = 'CloverUncovered'
  endif

  if a:cov.start_line == a:cov.end_line
    let l:pos = [[a:cov.start_line, a:cov.start_col, a:cov.end_col - a:cov.start_col]]
    return {'group': l:group, 'pos': l:pos}
  endif

  let l:end_position = strwidth(getline(a:cov.start_line)) - a:cov.start_col + 1
  let l:positions = [[a:cov.start_line, a:cov.start_col, l:end_position]]

  let l:current_line = a:cov.start_line
  while l:current_line < a:cov.end_line
    let l:current_line += 1
    call add(l:positions, l:current_line)
  endwhile

  call add(l:positions, [a:cov.end_line, a:cov.end_col-1])

  return {'group': l:group, 'pos': l:positions}
endfunction

function! s:ParseLine(line) abort
  let pat = '\([^:]\+\):\(\d\+\)\.\(\d\+\),\(\d\+\)\.\(\d\+\)\s\(\d\+\)\s\(\d\+\)'
  let tokens = matchlist(a:line, pat)

  let ret = {}
  let ret.file = tokens[1]
  let ret.start_line  = str2nr(tokens[2])
  let ret.start_col = str2nr(tokens[3])
  let ret.end_line = str2nr(tokens[4])
  let ret.end_col = str2nr(tokens[5])
  let ret.number_of_statements = str2nr(tokens[6])
  let ret.count = str2nr(tokens[7])
  return ret
endfunction
