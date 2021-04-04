if has('autocmd') && !has('gui_running')
  augroup colorset
    autocmd!
    autocmd ColorScheme one silent!
          \ call one#highlight('Normal', '', 'none', '')
  augroup END
endif

if (has("termguicolors"))
  set termguicolors
endif

if system("echo -n $(color get)") == "google-light"
  set background=light
else
  set background=dark
endif

let g:one_allow_italics = 1 " italic for comments

colorscheme one

let g:airline_theme='one'
