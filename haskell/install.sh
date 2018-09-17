#!/usr/bin/env sh

echo "Installling Haskell..."
sudo pacman -Syu ghc ghc-libs ghc-static cabal-install

ln -sfT ~/.dotfiles/haskell/ghci ~/.ghci

