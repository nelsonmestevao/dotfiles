#!/usr/bin/env sh

sudo pacman -Rs neovim

rm ~/.local/share/nvim/site/autoload/plug.vim

unlink ~/.config/nvim/init.vim

