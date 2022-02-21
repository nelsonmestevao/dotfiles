#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

install_package alacritty

mkdir -p ~/.config/alacritty
symlink ~/.dotfiles/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml

