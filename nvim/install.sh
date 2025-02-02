#!/usr/bin/env bash

set -Eeuo pipefail

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

#ask_for_sudo

#install_package neovim

mkdir -p ~/.config/nvim
symlink ~/.dotfiles/nvim/init.lua ~/.config/nvim/init.lua
