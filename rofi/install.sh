#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/utils.sh
. scripts/utils.sh
# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

ask_for_sudo
#install_package rofi

mkdir -p ~/.config/rofi
symlink ~/.dotfiles/rofi/config.rasi ~/.config/rofi/config.rasi
