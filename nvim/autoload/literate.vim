" LiterateVimscript
" =================
" a program that allows you to write CommonMark compatible markdown using
" vimscript inside of codeblocks and run it in Vim as if it were pure
" vimscript.
" Maintainer: Tyler Cipriani <tyler@tylercipriani.com>
" Version: 0.0.1

if exists("g:loaded_literate") || &cp
    finish
endif

let g:loaded_literate = 1

" Does a line look like it starts a fenced codeblock?
function! s:starts_codeblock(line) abort
    let line = a:line

    if line =~# "^ *```" && match(line, '```') <=# 3
        return 1
    endif

    if line =~# "^ *\\~\\~\\~" && match(line, '\~\~\~') <=# 3
        return 1
    endif
endfunction

" Find all CommonMark codeblocks. This supports both fenced codeblocks and
" indented codeblocks and follows the CommonMark 0.27 Spec
" <http://spec.commonmark.org/0.27/>
function! s:parse_codeblocks(file) abort
    let lines = []
    let code_block_open = 0
    let last_blank = 0
    let inside_block = 0

    for line in readfile(a:file)
        let open_block = s:starts_codeblock(line)

        if code_block_open ==# 0 && open_block
            let code_block_open = 1
            continue
        endif

        if code_block_open ==# 1 && open_block
            let code_block_open = 0
            continue
        endif

        if last_blank ==# 1 && code_block_open ==# 0 && line =~# '^    .*'
            let inside_block = 1
            let line = substitute(line, '^    ', '', '')
        endif

        if code_block_open !=# 1 && inside_block !=# 1
            continue
        endif

        call add(lines, line)

        if line =~# '^$'
            let last_blank = 1
         else
             let last_blank = 0
        endif
    endfor

    let temp = tempname()
    call writefile(lines, temp)
    exec "source " . temp
    " Reload all the plugins since this only happens on initialization
    " This does not seem to be necessary, but was during my testing...
    " runtime! plugin/**/*.vim
    call delete(temp)
endfunction


" Entrypoint. Accepts a single path and pases it off for parsing.
function! literate#load(path) abort
    let path = expand(a:path)
    if getftime(path) < 1
        return
    endif
    call s:parse_codeblocks(path)
endfunction
