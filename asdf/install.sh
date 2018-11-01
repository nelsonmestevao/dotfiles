#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Cloning asdf..."
git clone https://github.com/asdf-vm/asdf.git ~/.asdf

SAVED_DIR=$PWD

cd ~/.asdf || exit

git checkout "$(git describe --abbrev=0 --tags)"

cd "$SAVED_DIR" || exit

echo_info "Symling .asdfrc..."
ln -sfT ~/.dotfiles/asdf/asdfrc ~/.asdfrc

echo_info "Symling .tool-versions..."
ln -sfT ~/.dotfiles/asdf/tool-versions ~/.tool-versions

echo_info "Update asdf itself..."
asdf update

echo_info "Add asdf plugins..."
asdf plugin-add R
asdf plugin-add golang
asdf plugin-add julia
asdf plugin-add nodejs
asdf plugin-add ruby
asdf plugin-add rust

echo_info "Update all plugins..."
asdf plugin-update --all

echo_done "asdf configuration!"
