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
set background=dark

colorscheme vim-material

let g:airline_theme='material'
let g:airline_powerline_fonts = 1


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins                                                                      "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set runtimepath^=~/.vim/bundle/vim-ctrlp
set runtimepath^=~/.vim/bundle/vim-airline
set runtimepath^=~/.vim/bundle/vim-airline-themes
set runtimepath^=~/.vim/bundle/vim-surround
set runtimepath^=~/.vim/bundle/vim-commentary

