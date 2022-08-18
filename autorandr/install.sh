#!/usr/bin/env bash

#set -Eeuo pipefail

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

ask_for_sudo

install_package autorandr

mkdir -p "$HOME/.config/autorandr"

symlink_profiles() {
  ln -s ~/.dotfiles/autorandr/home ~/.config/autorandr
  ln -s ~/.dotfiles/autorandr/kelvin ~/.config/autorandr
}

execute symlink_profiles "Symlinking profiles folders..."
