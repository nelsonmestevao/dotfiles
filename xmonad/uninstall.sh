#!/bin/sh

echo "Installing XMonad..."
sudo apt-get remove xmonad libghc-xmonad-dev libghc-xmonad-contrib-dev xmobar xcompmgr nitrogen stalonetray moreutils synapse ssh-askpass-gnome suckless-tools

unlink  ~/.xmonad/xmonad.hs
