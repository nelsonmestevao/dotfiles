#!/bin/bash

apt install vim

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

ln -sfT ~/.dotfiles/vim/vimrc ~/.vimrc
