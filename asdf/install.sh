#!/usr/bin/env sh

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.6.3

echo "Symling .asdfrc..."
ln -sfT ~/.dotfiles/asdf/asdfrc        ~/.asdfrc

echo "Symling .tool-versions..."
ln -sfT ~/.dotfiles/asdf/tool-versions ~/.tool-versions

echo "Update asdf itself..."
asdf update

echo "Add asdf plugins..."
asdf plugin-add R
asdf plugin-add golang
asdf plugin-add haskell
asdf plugin-add julia
asdf plugin-add nodejs
asdf plugin-add ruby

echo "Update all plugins..."
asdf plugin-update --all

