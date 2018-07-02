#!/bin/bash

sudo apt-get remove software-properties-common
sudo add-apt-repository --remove ppa:neovim-ppa/stable
sudo apt-get remove neovim

rm ~/.local/share/nvim/site/autoload/plug.vim

unlink ~/.config/nvim/init.vim
