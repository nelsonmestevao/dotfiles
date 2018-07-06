"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions                                                                   "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Rename the current file
function! Rename()
  let current = expand('%')
  let new_file = input('New name: ', current)
  if new_file != current && new_file != ''
    exec ':saveas ' . new_file
    exec ':silent !rm ' . current
    redraw!
  endif
endfunction
