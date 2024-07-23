#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

ask_for_sudo

desktop-file-install --dir=/home/nelson/.local/share/applications  wezterm/term.desktop

update-desktop-database /home/nelson/.local/share/applications

mkdir -p ~/.config/wezterm
symlink ~/.dotfiles/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua
