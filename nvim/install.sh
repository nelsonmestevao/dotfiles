#!/bin/sh

sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt-get update
sudo apt install neovim

ln -sfT ~/dotfiles/nvim/init.vim ~/.config/nvim/init.vim
