function! DoRemote(arg)
  UpdateRemotePlugins
endfunction

let g:python_host_prog = '/Users/frm/.pyenv/versions/neovim2/bin/python'
let g:python3_host_prog = '/Users/frm/.pyenv/versions/neovim3/bin/python'

call plug#begin('~/.config/nvim/plugged')

" Ruby Toolkit
Plug 'slim-template/vim-slim'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-bundler'
Plug 'rhysd/vim-textobj-ruby'

" Elixir
Plug 'elixir-lang/vim-elixir', { 'for': 'elixir' }
Plug 'slashmili/alchemist.vim', { 'for': 'elixir' }
Plug 'c-brenn/phoenix.vim', { 'for': 'elixir' }
Plug 'andyl/vim-textobj-elixir', { 'for': 'elixir' }
Plug 'larrylv/ycm-elixir', { 'for': 'elixir' }

" JavaScript
Plug 'pangloss/vim-javascript', { 'for': ['javascript', 'javascript.jsx'] }
Plug 'mxw/vim-jsx', { 'for': ['javascript', 'javascript.jsx'] }

" Other Languages
Plug 'rust-lang/rust.vim', { 'for': 'rust' }
Plug 'Valloric/MatchTagAlways', { 'for': ['html', 'xml'] }

" Scheme
" Plug 'chriskempson/base16-vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'kristijanhusak/vim-hybrid-material'
Plug 'w0ng/vim-hybrid'

" All the rest
Plug 'SirVer/ultisnips'
Plug 'kassio/neoterm'
Plug 'janko-m/vim-test'
Plug 'tpope/vim-endwise'
Plug 'eapache/auto-pairs'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'terryma/vim-expand-region'
Plug 'kana/vim-textobj-user'
Plug 'w0rp/ale'
" Plug 'neomake/neomake'
Plug 'tpope/vim-abolish'

" Writing
Plug 'junegunn/goyo.vim', { 'for': ['markdown', 'txt', 'tex', 'bib'] }
Plug 'vim-scripts/VOoM', { 'for': ['markdown', 'txt', 'tex', 'bib'] }
Plug 'vim-scripts/LanguageTool', { 'for': ['markdown', 'txt', 'tex', 'bib'] }
Plug 'rhysd/vim-grammarous', { 'for': ['markdown', 'txt', 'tex', 'bib'] }
Plug 'gabrielelana/vim-markdown', { 'for': 'markdown' }
Plug 'junegunn/limelight.vim', { 'for': ['markdown', 'txt', 'tex', 'bib'] }
Plug 'beloglazov/vim-online-thesaurus'
Plug 'lervag/vimtex', { 'for': 'tex' }

Plug 'Valloric/YouCompleteMe'

Plug 'easymotion/vim-easymotion'
Plug 'haya14busa/incsearch.vim'
Plug 'haya14busa/incsearch-fuzzy.vim'
Plug 'haya14busa/incsearch-easymotion.vim'

Plug 'scrooloose/nerdcommenter'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-projectionist'
Plug 'tpope/vim-surround'
Plug 'christoomey/vim-tmux-navigator'
Plug 'wellle/tmux-complete.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'scrooloose/nerdtree', { 'on':  ['NERDTreeToggle', 'NERDTreeFind'] }

call plug#end()

" NERDTree
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <Leader>n :NERDTreeFind<CR>
let NERDTreeIgnore=['\.pyc', '\~$', '\.swo$', '\.swp$', '\.git', '\.hg', '\.svn', '\.bzr']
let g:NERDTreeDirArrows=1
let g:NERDTreeMouseMode=2
let g:NERDTreeShowHidden=1
let g:NERDTreeWinPos = "right"

" Close NERDTree if it's the only window open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

" Don't show whitespaces on NERDTree enter
autocmd FileType nerdtree setlocal nolist

" fzf
nmap <C-p> :Files<CR>
nmap <C-f> :Ag<CR>
nmap <leader>f :Tags <CR>
nmap <leader>b :BTags <CR>

" EasyMotion
" s for character search
" fs for character search across buffers
nmap <localleader>s <Plug>(easymotion-s)
nmap <localleader>fs <Plug>(easymotion-overwin-f)

" IncSearch
function! s:incsearch_config(...) abort
  return incsearch#util#deepextend(deepcopy({
  \   'modules': [incsearch#config#easymotion#module({'overwin': 1})],
  \   'keymap': {
  \     "\<CR>": '<Over>(easymotion)'
  \   },
  \   'is_expr': 0
  \ }), get(a:, 1, {}))
endfunction

function! s:config_easyfuzzymotion(...) abort
  return extend(copy({
  \   'converters': [
  \     incsearch#config#fuzzyword#converter(),
  \     incsearch#config#fuzzyspell#converter()
  \   ],
  \   'modules': [incsearch#config#easymotion#module({'overwin': 1})],
  \   'keymap': {"\<CR>": '<Over>(easymotion)'},
  \   'is_expr': 0,
  \   'is_stay': 1
  \ }), get(a:, 1, {}))
endfunction

noremap <silent><expr> /  incsearch#go(<SID>incsearch_config()) . '\v'
noremap <silent><expr> ?  incsearch#go(<SID>incsearch_config({'command': '?'})) . '\v'
" noremap <silent><expr> g/ incsearch#go(<SID>incsearch_config({'is_stay': 1})) . '\v'
map <silent><expr> <leader>/ incsearch#go(<SID>config_easyfuzzymotion())

" Deoplete
let g:deoplete#enable_at_startup = 1

" Neoterm
let g:neoterm_shell = 'zsh'
let g:neoterm_position='vertical'
let g:neoterm_size=50
nnoremap <silent> <localleader>l :call neoterm#clear()<cr>
nnoremap <silent> <localleader>q :call neoterm#close()<cr>

" Neotest
let test#strategy = "neoterm"
nnoremap <silent> <localleader>a :TestSuite<cr>
nnoremap <silent> <localleader>c :TestNearest<cr>
nnoremap <silent> <localleader>f :TestFile<cr>
nnoremap <silent> <localleader>, :TestLast<cr>

" Neomake
" let g:neomake_ruby_enabled_makers = ['rubocop']
" let g:neomake_css_enabled_makers = ['stylelint']
" let g:neomake_scss_enabled_makers = ['stylelint']
" let g:neomake_javascript_enabled_makers = ['eslint']
" let g:neomake_elixir_enabled_makers = ['credo']
"
" autocmd! BufWritePost * Neomake
" map <localleader>n :Neomake<CR>
"
" highlight NeomakeErrorSign ctermfg=1 ctermbg=8
" highlight NeomakeWarningSign ctermfg=3 ctermbg=8
"
" let g:neomake_error_sign={'text': '▶', 'texthl': 'NeomakeErrorSign'}
" let g:neomake_warning_sign={'text': '▶', 'texthl': 'NeomakeWarningSign'}

let g:ycm_server_python_interpreter="/Users/frm/.pyenv/versions/neovim3/bin/python"

" ale
let g:airline#extensions#ale#enabled = 1
let g:ale_sign_column_always = 1
let g:ale_emit_conflict_warnings = 0
let g:ale_ruby_rubocop_options = '--except Lint/Debugger'

let g:ale_sign_error = '▶'
let g:ale_sign_warning = '▶'
let g:ale_linters = {
      \ 'ruby': ['rubocop'],
      \ 'elixir': ['credo'],
      \ 'scss': ['stylelint'],
      \ 'javascript': [],
      \ 'typescript': ['tslint', 'tsserver'],
      \ }

let g:ale_fix_on_save = 1
let g:ale_fixers = {
      \ 'ruby': ['rubocop'],
      \ 'javascript': [],
      \ 'typescript': ['prettier']
      \ }

" Vim Projectionist
map <localleader>aa :A<CR>
nmap <localleader>av :AV<CR>
map <localleader>as :AS<CR>
map <localleader>at :AT<CR>

" UltiSnips
let g:UltiSnipsExpandTrigger="<C-j>"

" vim-expand-region
map K <Plug>(expand_region_expand)
map J <Plug>(expand_region_shrink)

" Writing plugins

" Autorun limelight
autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!

" Remap thesaurus
let g:online_thesaurus_map_keys = 0
nnoremap <localleader>t :OnlineThesaurusCurrentWord<CR>
let g:tex_flavor = 'tex'

let g:grammarous#use_vim_spelllang = 0
let g:grammarous#enable_spell_check = 1

let g:languagetool_jar='$HOME/.bin/languagetool/languagetool-commandline.jar'
