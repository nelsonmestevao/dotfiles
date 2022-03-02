#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

install_package picom

mkdir -p ~/.config/picom
symlink ~/.dotfiles/picom/picom.conf ~/.config/picom/picom.conf
