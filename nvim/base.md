# Editing behaviour

```vim
set nocompatible
```

## Encoding

```vim
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set fileformats=unix,dos
set bomb
set binary
```

```vim
set autoread              " read when a file is changed from the outside

" Fix backspace indent
set backspace=indent,eol,start
```

## Tabs

```vim
set tabstop=4
set softtabstop=0
set shiftwidth=4
set expandtab             " convert any tab to spaces
set smarttab
```

```vim
" Indentation
set autoindent            " always set autoindenting on
set copyindent            " copy the previous indentation on autoindenting
```

## Spelling

This will make the default spell language to English.

```vim
set spelllang=en
```

```vim
"" Enable hidden buffers
set hidden
```
## Split buffers

For some reason, I think the original way of VIM split is not the natural way.
This decides how it should.

```vim
set splitbelow
set splitright
```

## Searching

```vim
set hlsearch              " highlights the term you search for
set incsearch
set ignorecase
set smartcase             " when searching try to be smart about cases
```

## Swap files

Usually, VIM creates `.swp` files that you are currently editing. They are in
my `.gitignore_global` but I still prefer if it doesn't create these files
since I commit a log and often.

```vim
set nobackup
set noswapfile
```

## Terminal Shell

Use the shell that you predefine or use the one available.

```vim
if exists('$SHELL')
    set shell=$SHELL
else
    set shell=/bin/sh
endif
```

## Security

Disable `modelines` as a security precaution. Read more
[here](https://github.com/numirias/security/blob/master/doc/2019-06-04_ace-vim-neovim.md).

```vim
set modelines=0
set nomodeline
```

