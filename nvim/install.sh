#!/usr/bin/env bash

#set -Eeuo pipefail

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

ask_for_sudo

download_vim_plug() {
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

install_package neovim

#install_package ruby-neovim
#install_package nodejs-neovim

execute download_vim_plug "Installing vim-plug..."

mkdir -p ~/.config/nvim
symlink ~/.dotfiles/nvim/init.vim ~/.config/nvim/init.vim

symlink_ftplugin() {
  ln -s ~/.dotfiles/nvim/ftplugin ~/.config/nvim
}

execute symlink_ftplugin "Symlinking ftplugin folder..."
