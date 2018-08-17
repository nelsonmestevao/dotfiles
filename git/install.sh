#!/bin/bash

echo "Installing Git LFS..."
sudo pacman -Sy git-lfs

ln -sfT ~/.dotfiles/git/gitconfig ~/.gitconfig
