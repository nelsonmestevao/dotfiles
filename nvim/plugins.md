# Plugins

My plugin manager of choice is [vim-plug](https://github.com/junegunn/vim-plug)
which is a minimalist Vim plugin manager.

## Installation

This will download the last version of vim-plug script and will save it under
`~/.config/nvim/autoload/plug.vim`.

```vim
if !filereadable(expand('~/.config/nvim/autoload/plug.vim'))
  if !executable("curl")
    echoerr "You have to install curl or first install vim-plug yourself!"
    execute "q!"
  endif
  echo "Installing Vim-Plug..."
  echo ""
  silent !\curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall
endif
```

## List of Plugins

This is where the plugins will be clone to and load from.

```vim
call plug#begin(expand('~/.config/nvim/plugged'))
```

### Games

#### Tetris

```vim
Plug 'vim-scripts/TeTrIs.vim'
```

### IDE like plugins

```vim
Plug 'majutsushi/tagbar'
""" Tagbar
let g:tagbar_autofocus = 1

Plug 'tpope/vim-endwise'
Plug 'tpope/vim-surround'
Plug 'mhinz/vim-startify'
Plug 'jpalardy/vim-slime'
Plug 'luochen1990/rainbow'
Plug 'Yggdroot/indentLine'
Plug 'tpope/vim-commentary'
Plug 'Raimondi/delimitMate'
Plug 'RRethy/vim-illuminate'
Plug 'terryma/vim-multiple-cursors'
Plug 'bronson/vim-trailing-whitespace'
```
This plugin aim is to integrate Direnv and Vim. Because Vim can shell out to
other tools it's nice if the environment is in sync with the usual shell.

It also adds syntax highlighting for `.envrc` files.

```vim
Plug 'direnv/direnv.vim'
```
### Auto-completions

#### Ale

```vim
Plug 'w0rp/ale'

" Error and warning signs.
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚠'

" Enable integration with airline.
let g:airline#extensions#ale#enabled = 1
```

```vim
Plug 'neomake/neomake'
Plug 'sheerun/vim-polyglot'
Plug 'vim-syntastic/syntastic'
```

#### Deoplete

```vim
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif

let g:deoplete#enable_at_startup = 1
```

#### **fz**f

> fzf is a general-purpose command-line fuzzy finder

It's really powerful and it will be available system wise.

```vim
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" fzf {{{
set wildmode=list:longest,list:full
set wildignore+=*.o,*.obj,.git,*.rbc,*.pyc,__pycache__
let $FZF_DEFAULT_COMMAND =  "find * -path '*/\.*' -prune -o -path 'node_modules/**' -prune -o -path 'target/**' -prune -o -path 'dist/**' -prune -o  -type f -print -o -type l -print 2> /dev/null"
" }}}
```

```vim
""" Syntastic
let g:syntastic_always_populate_loc_list=1
let g:syntastic_error_symbol='✗'
let g:syntastic_warning_symbol='⚠'
let g:syntastic_style_error_symbol = '✗'
let g:syntastic_style_warning_symbol = '⚠'
let g:syntastic_auto_loc_list=1
let g:syntastic_aggregate_errors = 1


"" Snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"
let g:UltiSnipsEditSplit="vertical"

" EditorConfig
Plug 'editorconfig/editorconfig-vim'

" Org-Mode
Plug 'jceb/vim-orgmode'
Plug 'hsitz/VimOrganizer'
Plug 'vim-scripts/calendar.vim--Matsumoto'

" Git
Plug 'tpope/vim-git'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" NERDTree
Plug 'scrooloose/nerdtree'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'

"let NERDTreeShowHidden=1
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let g:NERDTreeChDirMode=2
let g:NERDTreeIgnore=['\.rbc$', '\~$', '\.pyc$', '\.db$', '\.sqlite$', '__pycache__']
let g:NERDTreeSortOrder=['^__\.py$', '\/$', '*', '\.swp$', '\.bak$', '\~$']
let g:NERDTreeShowBookmarks=1
let g:nerdtree_tabs_focus_on_files=1
let g:NERDTreeMapOpenInTabSilent = '<RightMouse>'
let g:NERDTreeWinSize = 40
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,*.db,*.sqlite
let g:NERDTreeDirArrowExpandable = nr2char(8200)
let g:NERDTreeDirArrowCollapsible = nr2char(8200)

" Vim Terminal
" Plug 'Shougo/deol.nvim'

" Vim-Session
Plug 'xolox/vim-misc'
Plug 'xolox/vim-session'

let g:session_directory = "~/.config/nvim/session"
let g:session_autoload = "no"
let g:session_autosave = "no"
let g:session_command_aliases = 1

" vim-airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Color Scheme
Plug 'rafi/awesome-vim-colorschemes'
Plug 'ryanoasis/vim-devicons'
```

### Languages

```vim
" C
Plug 'vim-scripts/c.vim', {'for': ['c', 'cpp']}
Plug 'ludwig/split-manpage.vim'
" Plug 'justinmk/vim-syntax-extra', { 'for': ['c', 'cpp', 'flex'] }

" Elixir
Plug 'elixir-editors/vim-elixir'
Plug 'carlosgaldino/elixir-snippets'

" Go
Plug 'zchee/deoplete-go', { 'do': 'make'}

let g:go_fmt_command = "goimports"
let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_structs = 1
let g:go_highlight_types = 1

" Haskell
" Plug 'dag/vim2hs'
Plug 'eagletmt/neco-ghc'
Plug 'neovimhaskell/haskell-vim'
Plug 'pbrisbin/vim-syntax-shakespeare'

"""" vim-haskell
let g:haskell_enable_quantification = 1   " to enable highlighting of `forall`
let g:haskell_enable_recursivedo = 1      " to enable highlighting of `mdo` and `rec`
let g:haskell_enable_arrowsyntax = 1      " to enable highlighting of `proc`
let g:haskell_enable_pattern_synonyms = 1 " to enable highlighting of `pattern`
let g:haskell_enable_typeroles = 1        " to enable highlighting of type roles
let g:haskell_enable_static_pointers = 1  " to enable highlighting of `static`
let g:haskell_backpack = 1                " to enable highlighting of backpack keywords

" HTML
Plug 'tpope/vim-haml'
Plug 'mattn/emmet-vim'
Plug 'hail2u/vim-css3-syntax'
Plug 'gorodinskiy/vim-coloresque'

" JavaScript
Plug 'jelera/vim-javascript-syntax'
Plug 'prettier/vim-prettier', { 'do': 'npm install' }

""" vim-prettier
let g:prettier#config#print_width = 40   " max line length that prettier will wrap on
let g:prettier#config#tab_width = 2      " number of spaces per indentation level
let g:prettier#config#use_tabs = 'false' " use tabs over spaces

" Julia
Plug 'JuliaEditorSupport/julia-vim'

" Markdown
Plug 'junegunn/goyo.vim' " distraction free writing
Plug 'godlygeek/tabular'
Plug 'junegunn/vim-emoji'
Plug 'iamcco/markdown-preview.nvim', { 'do': ':call mkdp#util#install()', 'for': 'markdown', 'on': 'MarkdownPreview' }


Plug 'plasticboy/vim-markdown'
let g:vim_markdown_math = 1
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_frontmatter = 1
"" let g:vim_markdown_folding_disabled = 0

" Python
Plug 'davidhalter/jedi-vim'
Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}

" Ruby
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-projectionist'
Plug 'thoughtbot/vim-rspec'
Plug 'ecomba/vim-ruby-refactoring'
```

This is necessary in order to close where there are no more plugins to install.

```vim
call plug#end()
```

