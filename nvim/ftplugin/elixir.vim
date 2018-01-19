let g:alchemist_iex_term_size = 15
let g:alchemist_iex_term_split = 'split'

map <localleader>d orequire IEx; IEx.pry<ESC>:w<CR>
map <localleader>D Orequire IEx; IEx.pry<ESC>:w<CR>
map <localleader>t <Esc>:IEx<CR>
