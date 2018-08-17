#!/bin/sh

echo "Installing LaTeX..."
sudo pacman -S texlive-core

ln -sfT ~/.dotfiles/latex/latexmkrc ~/.latexmkrc

