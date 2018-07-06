#!/bin/bash

echo "Installling Haskell..."
sudo apt-get install haskell-platform -yqq

ln -sfT ~/.dotfiles/haskell/ghci ~/.ghci
