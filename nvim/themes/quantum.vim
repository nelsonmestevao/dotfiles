if (has("termguicolors"))
  set termguicolors
endif

if system("echo -n $(color get)") == "google-light"
  set background=light
else
  set background=dark
endif

colorscheme quantum

let g:airline_theme='quantum'
