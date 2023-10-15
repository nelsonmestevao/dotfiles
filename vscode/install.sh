#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/execs.sh
. scripts/execs.sh

function install_extensions() {
  declare -a extensions=(
    GitHub.github-vscode-theme
    # JakeBecker.elixir-ls
    lexical-lsp.lexical
    MS-vsliveshare.vsliveshare
    ms-vscode.makefile-tools
    PKief.material-icon-theme
    SimonSiefke.svg-preview
    bradlc.vscode-tailwindcss
    eamodio.gitlens
    streetsidesoftware.code-spell-checker
    haskell.haskell
    justusadam.language-haskell
    miguelsolorio.fluent-icons
    # pantajoe.vscode-elixir-credo
    victorbjorklund.phoenix
    vscodevim.vim
  )

  for extension in "${extensions[@]}"; do
    code --install-extension $extension
  done
}

execute install_extensions "Installing VS Code extensions..."

mkdir -p ~/.config/Code/User
symlink ~/.dotfiles/vscode/settings.json ~/.config/Code/User/settings.json
