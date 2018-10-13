#!/usr/bin/env sh

echo "Installling Haskell..."
sudo apt install haskell-platform

ln -sfT ~/.dotfiles/haskell/ghci ~/.ghci

