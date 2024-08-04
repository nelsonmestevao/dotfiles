#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh

function install_ghcup() {
  if [[ -f "${HOME}/.ghcup/bin/ghcup" ]]; then
    echo "GHCup is already installed."
    return
  fi

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
    cabal install $tool
  done
}

function download_package_list() {
  cabal update
}

symlink "$HOME/.dotfiles/haskell/ghci" "$HOME/.ghci"

# sudo dnf install gmp-devel

execute install_ghcup "Installing GHCup..."

source haskell/haskell.init

execute download_package_list "Download the package list for all remotes..."
execute install_libraries "Installing Haskell libraries..."
execute install_tools "Installing Haskell tools..."
