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

install_package autorandr

mkdir -p "$HOME/.config/autorandr"

symlink_profiles() {
  ln -s ~/.dotfiles/autorandr/home ~/.config/autorandr
  ln -s ~/.dotfiles/autorandr/kelvin ~/.config/autorandr
  ln -s ~/.dotfiles/autorandr/chill ~/.config/autorandr
  ln -s ~/.dotfiles/autorandr/granjinhos ~/.config/autorandr
}

execute symlink_profiles "Symlinking profiles folders..."
