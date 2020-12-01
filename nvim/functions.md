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

## Get the commit for current line

```vim
function! Gitline()
    let Currdir = getcwd()
    cd %:p:h
    if system("[ -d .git ] && echo 1") == ""
  echo "File not in git repository"
  call chdir(Currdir)
  return
    endif
    if system("git ls-files " . expand("%:p")) == ""
  echo "File not under version control"
  call chdir(Currdir)
  return
    endif
    let Cmdstr = "read ! git log -n 1 -L " . line(".") . ",+1:" . expand("%:p")
    let &splitbelow = 1
    if bufwinnr("Gitlog") > 0
  wincmd j
  %d
    else
  sp Gitlog
    endif
    set buftype=nofile
    set ft=git
    exe Cmdstr
    1
    wincmd k
    call chdir(Currdir)
    let &splitbelow = 0
endfunction

nnoremap <leader>l :call Gitline()<cr><cr>
nnoremap <leader>c :if bufwinnr("Gitlog") > 0 \| bdelete Gitlog \| endif<cr>
```

