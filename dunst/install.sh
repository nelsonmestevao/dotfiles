#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

install_package dunst

symlink "$HOME/.dotfiles/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"
