#!/bin/sh

sudo apt install vim

git clone git://github.com/kien/ctrlp.vim.git              ~/.vim/bundle/vim-ctrlp
git clone git://github.com/vim-airline/vim-airline         ~/.vim/bundle/vim-airline
git clone git://github.com/vim-airline/vim-airline-themes  ~/.vim/bundle/vim-airline-themes
git clone git://github.com/tpope/vim-surround.git          ~/.vim/bundle/vim-surround
git clone git://github.com/tpope/vim-commentary.git        ~/.vim/bundle/vim-commentary

# vim colors
curl https://raw.githubusercontent.com/kristijanhusak/vim-hybrid-material/master/colors/hybrid_material.vim > ~/.vim/colors/hybrid_material.vim
curl https://raw.githubusercontent.com/skielbasa/vim-material-monokai/master/colors/material-monokai.vim    > ~/.vim/colors/material-monokai.vim
curl https://raw.githubusercontent.com/hzchirs/vim-material/master/colors/vim-material.vim                  > ~/.vim/colors/vim-material.vim

# vim airline themes

curl https://raw.githubusercontent.com/hzchirs/vim-material/master/autoload/airline/themes/material.vim     > ~/.vim/bundle/vim-airline-themes/autoload/airline/themes/material.vim

ln -sfT ~/dotfiles/vim/.vimrc ~/.vimrc
