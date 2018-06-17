"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Editing behaviour                                                           "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set encoding=utf-8
set termencoding=utf-8
if has("termguicolors")
  set termguicolors
endif
set spelllang=en          " spell check set to English
set wrap
set showmode              " always show what mode we're currently editing in
set tabstop=2             " determine how many columns a tab counts
set softtabstop=2
set shiftwidth=2          " determine how many columns text is indented when using reindent operations
set expandtab             " convert any tab to spaces
set smarttab
set autoindent            " always set autoindenting on
set copyindent            " copy the previous indentation on autoindenting
set number relativenumber " set hybrid line numbers
set showmatch             " set show matching parenthesis
set cursorline            " underline the current line, for quick orientation
"set cursorcolumn
set colorcolumn=80
set title                 " change the terminal's title
set autoread              " read when a file is changed from the outside
set smartcase             " when searching try to be smart about cases
set hlsearch              " highlights the term you search for

" Highlight whitespaces
set list
set listchars=""
set listchars+=tab:>-
set listchars+=trail:•
set listchars+=nbsp:•

" Fix horizontal and vertical splits
set splitbelow
set splitright
