#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

function download_ghcup() {
  curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
}

symlink "$HOME/.dotfiles/haskell/ghci" "$HOME/.ghci"

download_ghcup
