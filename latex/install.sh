#!/bin/sh

echo "Installing LaTeX..."
sudo apt-get install texlive-full -yqq

ln -sfT ~/.dotfiles/latex/latexmkrc ~/.latexmkrc

