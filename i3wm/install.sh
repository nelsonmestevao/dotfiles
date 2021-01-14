#!/usr/bin/env bash

#set -Eeuo pipefail

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

mkdir -p "$HOME/.i3"
symlink "$HOME/.dotfiles/i3wm/config" "$HOME/.i3/config"
