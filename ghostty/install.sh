#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh

mksymlink "$DOTFILES/ghostty/config" "$HOME/.config/ghostty/config"
mksymlink "$DOTFILES/ghostty/themes" "$HOME/.config/ghostty/themes"
