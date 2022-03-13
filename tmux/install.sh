#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

ask_for_sudo

install_package tmux

install_package tmuxinator

execute "git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm" "Clonning tmux plugin manager..."

symlink ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf
