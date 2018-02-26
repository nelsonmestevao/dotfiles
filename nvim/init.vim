""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins                                                                      "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall | nested source $MYVIMRC
endif

" Plugins will be downloaded under the specified directory.
call plug#begin('~/.local/share/nvim/plugged')

Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'sheerun/vim-polyglot'
Plug 'honza/vim-snippets'
Plug 'prettier/prettier'
Plug 'prettier/vim-prettier', { 'do': 'yarn install' }
Plug 'justinmk/vim-syntax-extra', { 'for': ['c', 'cpp', 'flex'] }
Plug 'neomake/neomake'

Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-endwise'
Plug 'scrooloose/nerdcommenter'
Plug 'chrisbra/Colorizer'

Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

Plug 'tpope/vim-fugitive'

Plug 'ctrlpvim/ctrlp.vim'

Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'morhetz/gruvbox'
Plug 'ryanoasis/vim-devicons'

" List ends here. Plugins become visible to Vim after this call.
call plug#end()

""" deoplete
let g:deoplete#enable_at_startup = 1
" use tab to forward cycle
inoremap <silent><expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"
" use tab to backward cycle
inoremap <silent><expr><s-tab> pumvisible() ? "\<c-p>" : "\<s-tab>"
" Close the documentation window when completion is done
autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

""" vim-airline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'default'
let g:airline_powerline_fonts = 1
let g:airline_theme = 'gruvbox'

""" vim-devicons
let g:webdevicons_enable = 1 " loading the plugin
let g:webdevicons_enable_nerdtree = 1 " adding the flags to NERDTree

""" Colorizer
let g:colorizer_auto_filetype='css,html,scss,slim,sass,less'

""" NERDTree
"let NERDTreeShowHidden=1
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

""" Neomaker
call neomake#configure#automake('w') " When writing a buffer
call neomake#configure#automake('nw', 750) " When writing a buffer, and on normal mode changes (after 750ms)
call neomake#configure#automake('rw', 1000) " When reading a buffer (after 1s), and when writing

""" vim-prettier
let g:prettier#config#print_width = 40 " max line length that prettier will wrap on
let g:prettier#config#tab_width = 2 " number of spaces per indentation level
let g:prettier#config#use_tabs = 'false' " use tabs over spaces

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Editing behaviour                                                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set encoding=utf-8
set termencoding=utf-8
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

if has("termguicolors")
  set termguicolors
endif

let g:enable_bold_font=1
let g:enable_italic_font = 1

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

nnoremap <c-s> :w<CR>
inoremap <c-s> <Esc>:w<CR>a
vnoremap <c-s> <Esc>:w<CR>

tnoremap <Esc> <C-\><C-n>

" Better pane movement
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

map <C-\> :NERDTreeToggle<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors and Fonts                                                             "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

syntax enable             " enable syntax highlighting
syntax on

let NVIM_TUI_ENABLE_CURSOR_SHAPE=1
set background=dark
colorscheme gruvbox
let g:seiya_auto_enable=1
let g:seiya_target_groups = ['guibg']
