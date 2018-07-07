"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Editing behaviour                                                           "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible

" Encoding
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set bomb
set binary

set fileformats=unix,dos

set autoread              " read when a file is changed from the outside

" Fix backspace indent
set backspace=indent,eol,start

" Tabs
set tabstop=4
set softtabstop=0
set shiftwidth=4
set expandtab             " convert any tab to spaces
set smarttab

" Indentation
set autoindent            " always set autoindenting on
set copyindent            " copy the previous indentation on autoindenting

" Spelling
set spelllang=en          " spell check set to English

"" Enable hidden buffers
set hidden

" Fix horizontal and vertical splits
set splitbelow
set splitright

"" Searching
set hlsearch              " highlights the term you search for
set incsearch
set ignorecase
set smartcase             " when searching try to be smart about cases

"" Directories for swp files
set nobackup
set noswapfile

if exists('$SHELL')
    set shell=$SHELL
else
    set shell=/bin/sh
endif

