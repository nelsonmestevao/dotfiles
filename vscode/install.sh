#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

function install_extensions() {
  declare -a extensions=(
    elixir-lsp.elixir-ls
    GitHub.github-vscode-theme
    haskell.haskell
    justusadam.language-haskell
    miguelsolorio.fluent-icons
    PKief.material-icon-theme
    victorbjorklund.phoenix
    vscodevim.vim
  )

  for extension in "${extensions[@]}"; do
    code --install-extension $extension
  done
}

execute install_extensions "Installing VS Code extensions..."
