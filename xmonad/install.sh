#!/bin/sh


echo "Installing XMonad..."
sudo apt-get install xmonad libghc-xmonad-dev libghc-xmonad-contrib-dev xmobar xcompmgr nitrogen stalonetray moreutils synapse ssh-askpass-gnome suckless-tools

cabal update
cabal install xmonad xmonad-contrib

mkdir -p ~/.xmonad
ln -sfT ~/.dotfiles/xmonad/xmonad.hs ~/.xmonad/xmonad.hs
