#!/usr/bin/env sh

echo "Installing Git LFS..."
sudo pacman -Syu git-lfs --needed --noconfirm

ln -sfT "$HOME/.dotfiles/git/gitconfig"  "$HOME/.gitconfig"

