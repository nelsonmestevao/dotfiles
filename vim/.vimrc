""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Editing behaviour                                                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set spelllang=en          " spell check set to English
set showmode              " always show what mode we're currently editing in
set tabstop=4             " determine how many columns a tab counts
set shiftwidth=4          " determine how many columns text is indented when using reindent operations
set expandtab             " convert any tab to spaces
set autoindent            " always set autoindenting on
set copyindent            " copy the previous indentation on autoindenting
set number relativenumber " set hybrid line numbers
set showmatch             " set show matching parenthesis
set cursorline            " underline the current line, for quick orientation
set title                 " change the terminal's title
set autoread              " read when a file is changed from the outside
set smartcase             " when searching try to be smart about cases
set hlsearch              " highlights the term you search for
set termencoding=utf-8
set encoding=utf-8


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Keymap                                                                       "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

nnoremap tn :tabnew<Space>

nnoremap tk :tabnext<CR>
nnoremap tj :tabprev<CR>

nnoremap th :tabfirst<CR>
nnoremap tl :tablast<CR>

inoremap kj <Esc>
cnoremap kj <Esc>

map <C-s> <ESC>:w<CR> " saving buffers

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors and Fonts                                                             "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

syntax enable             " enable syntax highlighting

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins                                                                      "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Plugins will be downloaded under the specified directory.
call plug#begin('~/.vim/plugged')

" Declare the list of plugins.
Plug 'neovimhaskell/haskell-vim'
Plug 'bling/vim-airline'

" List ends here. Plugins become visible to Vim after this call.
call plug#end()
