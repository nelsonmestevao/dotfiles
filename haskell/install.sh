#!/usr/bin/env sh

echo "Installing haskell..."
sudo pacman -S stack

echo "Symling .ghci..."
ln -sfT ~/.dotfiles/haskell/ghci ~/.ghci

