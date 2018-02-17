" so ~/.dotfiles/nvim/rc/base.vim
" so ~/.dotfiles/nvim/rc/maps.vim
" so ~/.dotfiles/nvim/rc/plugins.vim
" so ~/.dotfiles/nvim/rc/skel.vim
" so ~/.dotfiles/nvim/rc/scheme.vim
" so ~/.dotfiles/nvim/rc/filetypes.vim

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins                                                                      "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall | nested source $MYVIMRC
endif

" startup for vim-plug
call plug#begin('~/.local/share/nvim/plugged')

Plug 'sheerun/vim-polyglot'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"Plug 'valloric/youcompleteme'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline-themes'
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'scrooloose/nerdcommenter'
Plug 'neomake/neomake'
Plug 'tpope/vim-surround'
Plug 'jiangmiao/auto-pairs'
Plug 'bling/vim-airline'
Plug 'ryanoasis/vim-devicons'
Plug 'chrisbra/Colorizer'
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue']}
Plug 'justinmk/vim-syntax-extra', { 'for': ['c', 'cpp', 'flex'] }

"colorschemes
Plug 'morhetz/gruvbox'

call plug#end()

""" Colorizer
let g:colorizer_auto_filetype='css,html,scss,slim,sass,less'

""" deoplete
let g:deoplete#enable_at_startup = 1
" use tab to forward cycle
inoremap <silent><expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"
" use tab to backward cycle
inoremap <silent><expr><s-tab> pumvisible() ? "\<c-p>" : "\<s-tab>"
" Close the documentation window when completion is done
autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

""" NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

""" Neomaker
" When writing a buffer.
call neomake#configure#automake('w')
" When writing a buffer, and on normal mode changes (after 750ms).
call neomake#configure#automake('nw', 750)
" When reading a buffer (after 1s), and when writing.
call neomake#configure#automake('rw', 1000)

""" syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Editing behaviour                                                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set spelllang=en          " spell check set to English
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
set termguicolors
set termencoding=utf-8
set encoding=utf-8

set wrap

" Highlight whitespaces
set list
set listchars=""
set listchars+=tab:>-
set listchars+=trail:•
set listchars+=nbsp:•

" Fix horizontal and vertical splits
set splitbelow
set splitright

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

" Better pane movement
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

"map <C-s> <ESC>:w<CR> " saving buffers

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors and Fonts                                                             "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let NVIM_TUI_ENABLE_CURSOR_SHAPE=1
set background=dark
colorscheme gruvbox
let g:seiya_auto_enable=1
let g:seiya_target_groups = ['guibg']

" vim-airline settings
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme = 'gruvbox'
let g:airline_powerline_fonts = 1
