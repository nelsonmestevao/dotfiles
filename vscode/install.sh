#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh

function install_extensions() {
  declare -a extensions=($(cat ./vscode/extensions.txt | tr "\n" " "))

  for extension in "${extensions[@]}"; do
    code --install-extension $extension
  done
}

execute install_extensions "Installing VS Code extensions..."

mkdir -p ~/.config/Code/User
symlink ~/.dotfiles/vscode/settings.json ~/.config/Code/User/settings.json
symlink ~/.dotfiles/vscode/keybindings.json ~/.config/Code/User/keybindings.json
