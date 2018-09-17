#!/usr/bin/env sh

echo "Installing Mercurial..."
sudo pacman -Syu mercurial --needed --noconfirm

ln -sfT ~/.dotfiles/hg/hgrc ~/.hgrc

