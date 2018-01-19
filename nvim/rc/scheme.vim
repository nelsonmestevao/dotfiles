syntax enable

" Highlights current line
set cursorline

" Number of lines between cursor and scroll
set scrolloff=4

" Fix for background using tmux on Linux
if &term =~ '256color'
  " disable Background Color Erase (BCE) so that color schemes
  " render properly when inside 256-color tmux and GNU screen.
  " see also http://snk.tuxfamily.org/log/vim-256color-bce.html
  set t_ut=
endif

set t_Co=256

let g:enable_bold_font=1
let g:enable_italic_font = 1

" Neovim runs in true color mode,
" which means iTerm2 falls back to default pallette.
" See https://github.com/chriskempson/base16-vim/issues/69
" and https://github.com/chriskempson/base16-vim/issues/111
if has("termguicolors")
  set termguicolors
endif

set background=dark

" Preventing airline from hiding with NerdTreeToggle
set laststatus=2
