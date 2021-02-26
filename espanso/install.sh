#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

install_package espanso

ln -s "$HOME/.dotfiles/espanso/user/" "$HOME/.config/espanso"
symlink "$HOME/.dotfiles/espanso/default.yml" "$HOME/.config/espanso/default.yml"
