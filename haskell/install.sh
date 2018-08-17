#!/usr/bin/env sh

echo "Installling Haskell..."
sudo pacman -Syy ghc cabal-install

ln -sfT ~/.dotfiles/haskell/ghci ~/.ghci
