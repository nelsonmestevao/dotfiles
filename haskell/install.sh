#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/execs.sh
. scripts/execs.sh

function install_ghcup() {
  curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh
}

function install_libraries() {
  declare -a libs=(HUnit gloss)

  for lib in "${libs[@]}"; do
    cabal install --lib $lib
  done
}

function install_tools() {
  declare -a tools=(hlint hindent)

  for tool in "${tools[@]}"; do
    cabal install --lib $tool
  done
}

symlink "$HOME/.dotfiles/haskell/ghci" "$HOME/.ghci"

execute install_ghcup "Installing GHCup..."
execute install_libraries "Installing Haskell libraries..."
execute install_tools "Installing Haskell tools..."
