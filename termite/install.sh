#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

install_package termite

mkdir -p ~/.config/termite
symlink ~/.dotfiles/termite/option ~/.config/termite/option
symlink ~/.dotfiles/termite/theme ~/.config/termite/theme
symlink ~/.dotfiles/termite/color/ ~/.config/termite/color
