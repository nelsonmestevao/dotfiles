#!/usr/bin/env sh

sudo pacman -Syu termite --needed --noconfirm

ln -sfT ~/.dotfiles/termite/config  ~/.config/termite/config

