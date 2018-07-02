#!/bin/bash

echo "Installing Vim..."
sudo apt-get install vim -yqq

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

ln -sfT ~/.dotfiles/vim/vimrc ~/.vimrc
