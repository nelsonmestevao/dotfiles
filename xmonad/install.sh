#!/bin/sh

sudo apt-get install xmonad suckless-tools
cabal update
cabal install xmonad xmonad-contrib

mkdir -p ~/.xmonad
ln -sfT ~/.dotfiles/xmonad/xmonad.hs ~/.xmonad/xmonad.hs
