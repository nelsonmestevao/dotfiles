#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/execs.sh
#. scripts/execs.sh

function install_extensions() {
  declare -a extensions=(
    GitHub.github-vscode-theme
    JakeBecker.elixir-ls
    MS-vsliveshare.vsliveshare
    PKief.material-icon-theme
    eamodio.gitlens
    miguelsolorio.fluent-icons
    pantajoe.vscode-elixir-credo
    vscodevim.vim
  )

  for extension in "${extensions[@]}"; do
    code --install-extension $extension
  done
}

install_extensions

mkdir -p "$HOME/Library/Application Support/Code/User"
ln -s ~/.dotfiles/vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"













