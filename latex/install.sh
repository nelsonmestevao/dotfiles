#!/usr/bin/env sh

echo "Installing LaTeX..."
sudo pacman -Syu texlive-core --needed --noconfirm

ln -sfT ~/.dotfiles/latex/latexmkrc ~/.latexmkrc

