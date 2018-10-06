#!/usr/bin/env sh

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.5.1

ln -sfT ~/.dotfiles/asdf/asdfrc        ~/.asdfrc
ln -sfT ~/.dotfiles/asdf/tool-versions ~/.tool-versions

