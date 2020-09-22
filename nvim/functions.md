# Functions

## Rename the current file

This function when called gives you the option to change the file name that you
are currently editing.

```vim
function! Rename()
  let current = expand('%')
  let new_file = input('New name: ', current)
  if new_file != current && new_file != ''
    exec ':saveas ' . new_file
    exec ':silent !rm ' . current
    redraw!
  endif
endfunction
```

## Writing mode

Change the spell between English and Portuguese more easily.

```vim
command PT set spell | set spelllang=pt
command EN set spell | set spelllang=pt
```

