#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing Git LFS..."
_install git-lfs

echo_info "Installing Git Fuzzy..."
git clone https://github.com/bigH/git-fuzzy.git "$HOME/.git-fuzzy"

echo_info "Symlink ~/.gitconfig"
ln -sfT "$HOME/.dotfiles/git/gitconfig" "$HOME/.gitconfig"

echo_done "Git configuration!"
