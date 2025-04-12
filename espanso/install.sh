#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

mkdir -p "$HOME/.config/espanso"

ln -s "$HOME/.dotfiles/espanso/config" "$HOME/.config/espanso/config"
ln -s "$HOME/.dotfiles/espanso/match" "$HOME/.config/espanso/match"
