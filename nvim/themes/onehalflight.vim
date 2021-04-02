" If you want to match colors in vim and in your terminal exactly, you must
" enable true colors (24 bit).
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

syntax on
set t_Co=256
set cursorline

colorscheme onehalflight

let g:airline_theme='onehalflight'

