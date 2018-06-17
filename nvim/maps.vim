"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Keymap                                                                      "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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

" A syntax for placeholders
" Pressing Control-j jumps to the next match.
inoremap <c-j> <Esc>/<++><CR><Esc>cf>

" Better pane movement
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

map <C-\> :NERDTreeToggle<CR>

"""Git
  autocmd FileType gitcommit setlocal spell

"""LaTeX
  " Word count:
  autocmd FileType tex map <F3> :w !detex \| wc -w<CR>
  autocmd FileType tex inoremap <F3> <Esc>:w !detex \| wc -w<CR>
  " Compile document using xelatex:
  autocmd FileType tex inoremap <F5> <Esc>:!xelatex<space><c-r>%<Enter>a
  autocmd FileType tex nnoremap <F5> :!xelatex<space><c-r>%<Enter>
  " Code snippets
  autocmd FileType tex inoremap ;fr \begin{frame}<Enter>\frametitle{}<Enter><Enter><++><Enter><Enter>\end{frame}<Enter><Enter><++><Esc>6kf}i
  autocmd FileType tex inoremap ;fi \begin{fitch}<Enter><Enter>\end{fitch}<Enter><Enter><++><Esc>3kA
  autocmd FileType tex inoremap ;exe \begin{exe}<Enter>\ex<Space><Enter>\end{exe}<Enter><Enter><++><Esc>3kA
  autocmd FileType tex inoremap ,em \emph{}<++><Esc>T{i
  autocmd FileType tex inoremap ,bf \textbf{}<++><Esc>T{i
  autocmd FileType tex inoremap ,it \textit{}<++><Esc>T{i
  autocmd FileType tex inoremap ,ct \textcite{}<++><Esc>T{i
  autocmd FileType tex inoremap ;cp \parencite{}<++><Esc>T{i
  autocmd FileType tex inoremap ;glos {\gll<Space><++><Space>\\<Enter><++><Space>\\<Enter>\trans{``<++>''}}<Esc>2k2bcw
  autocmd FileType tex inoremap ;x \begin{xlist}<Enter>\ex<Space><Enter>\end{xlist}<Esc>kA<Space>
  autocmd FileType tex inoremap ,ol \begin{enumerate}<Enter><Enter>\end{enumerate}<Enter><Enter><++><Esc>3kA\item<Space>
  autocmd FileType tex inoremap ,ul \begin{itemize}<Enter><Enter>\end{itemize}<Enter><Enter><++><Esc>3kA\item<Space>
  autocmd FileType tex inoremap ,li <Enter>\item<Space>
  autocmd FileType tex inoremap ,ref \ref{}<Space><++><Esc>T{i
  autocmd FileType tex inoremap ,tab \begin{tabular}<Enter><++><Enter>\end{tabular}<Enter><Enter><++><Esc>4kA{}<Esc>i
  autocmd FileType tex inoremap ;ot \begin{tableau}<Enter>\inp{<++>}<Tab>\const{<++>}<Tab><++><Enter><++><Enter>\end{tableau}<Enter><Enter><++><Esc>5kA{}<Esc>i
  autocmd FileType tex inoremap ;can \cand{}<Tab><++><Esc>T{i
  autocmd FileType tex inoremap ;con \const{}<Tab><++><Esc>T{i
  autocmd FileType tex inoremap ;v \vio{}<Tab><++><Esc>T{i
  autocmd FileType tex inoremap ,a \href{}{<++>}<Space><++><Esc>2T{i
  autocmd FileType tex inoremap ,sc \textsc{}<Space><++><Esc>T{i
  autocmd FileType tex inoremap ,chap \chapter{}<Enter><Enter><++><Esc>2kf}i
  autocmd FileType tex inoremap ,sec \section{}<Enter><Enter><++><Esc>2kf}i
  autocmd FileType tex inoremap ,ssec \subsection{}<Enter><Enter><++><Esc>2kf}i
  autocmd FileType tex inoremap ,sssec \subsubsection{}<Enter><Enter><++><Esc>2kf}i
  autocmd FileType tex inoremap ;st <Esc>F{i*<Esc>f}i
  autocmd FileType tex inoremap ;beg \begin{DELRN}<Enter><++><Enter>\end{DELRN}<Enter><Enter><++><Esc>4k0fR:MultipleCursorsFind<Space>DELRN<Enter>c
  autocmd FileType tex inoremap ;up <Esc>/usepackage<Enter>o\usepackage{}<Esc>i
  autocmd FileType tex nnoremap ;up /usepackage<Enter>o\usepackage{}<Esc>i
  autocmd FileType tex inoremap ;tt \texttt{}<Space><++><Esc>T{i
  autocmd FileType tex inoremap ;bt {\blindtext}
  autocmd FileType tex inoremap ;nu $\varnothing$
  autocmd FileType tex inoremap ;col \begin{columns}[T]<Enter>\begin{column}{.5\textwidth}<Enter><Enter>\end{column}<Enter>\begin{column}{.5\textwidth}<Enter><++><Enter>\end{column}<Enter>\end{columns}<Esc>5kA
  autocmd FileType tex inoremap ;rn (\ref{})<++><Esc>F}i
"""LATEX Logical symbols
  autocmd FileType tex inoremap ;m $$<Space><++><Esc>2T$i 
  autocmd FileType tex inoremap ;M $$$$<Enter><Enter><++><Esc>2k$hi
  autocmd FileType tex inoremap ;neg {\neg}
  autocmd FileType tex inoremap ;V {\vee}
  autocmd FileType tex inoremap ;or {\vee}
  autocmd FileType tex inoremap ;L {\wedge}
  autocmd FileType tex inoremap ;and {\wedge}
  autocmd FileType tex inoremap ;ra {\rightarrow}
  autocmd FileType tex inoremap ;la {\leftarrow}
  autocmd FileType tex inoremap ;lra {\leftrightarrow}
  autocmd FileType tex inoremap ;fa {\forall}
  autocmd FileType tex inoremap ;ex {\exists}
  autocmd FileType tex inoremap ;dia	{\Diamond}
  autocmd FileType tex inoremap ;box	{\Box}
  autocmd FileType tex inoremap ;gt	{\textgreater}
  autocmd FileType tex inoremap ;lt	{\textless}

""".bib
  autocmd FileType bib inoremap ,a @article{<Enter><tab>author<Space>=<Space>"<++>",<Enter><tab>year<Space>=<Space>"<++>",<Enter><tab>title<Space>=<Space>"<++>",<Enter><tab>journal<Space>=<Space>"<++>",<Enter><tab>volume<Space>=<Space>"<++>",<Enter><tab>pages<Space>=<Space>"<++>",<Enter><tab>}<Enter><++><Esc>8kA,<Esc>i
  autocmd FileType bib inoremap ,b @book{<Enter><tab>author<Space>=<Space>"<++>",<Enter><tab>year<Space>=<Space>"<++>",<Enter><tab>title<Space>=<Space>"<++>",<Enter><tab>publisher<Space>=<Space>"<++>",<Enter><tab>}<Enter><++><Esc>6kA,<Esc>i
  autocmd FileType bib inoremap ,c @incollection{<Enter><tab>author<Space>=<Space>"<++>",<Enter><tab>title<Space>=<Space>"<++>",<Enter><tab>booktitle<Space>=<Space>"<++>",<Enter><tab>editor<Space>=<Space>"<++>",<Enter><tab>year<Space>=<Space>"<++>",<Enter><tab>publisher<Space>=<Space>"<++>",<Enter><tab>}<Enter><++><Esc>8kA,<Esc>i

"MARKDOWN
  autocmd BufRead,BufNewFile *.md,*rmd setlocal spell
  autocmd Filetype markdown,rmd inoremap ,i ![](<++>)<++><Esc>F[a
  autocmd Filetype markdown,rmd inoremap ,a [](<++>)<++><Esc>F[a
  autocmd Filetype markdown,rmd inoremap ,1 #<Space><Enter><++><Esc>kA
  autocmd Filetype markdown,rmd inoremap ,2 ##<Space><Enter><++><Esc>kA
  autocmd Filetype markdown,rmd inoremap ,3 ###<Space><Enter><++><Esc>kA
  autocmd Filetype markdown map <F5> :!pandoc<space><C-r>%<space>--pdf-engine=xelatex<space>-o<space><C-r>%.pdf<Enter><Enter>
  autocmd Filetype rmd map <F5> :!echo<space>"require(rmarkdown);<space>render('<c-r>%')"<space>\|<space>R<space>--vanilla<enter>
  autocmd Filetype rmd inoremap ;r ```{r}<CR>```<CR><CR><esc>2kO
