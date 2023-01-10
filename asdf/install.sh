#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

ASDF_PATH_DIR="$HOME/.asdf"

execute "git clone https://github.com/asdf-vm/asdf.git $ASDF_PATH_DIR" "Clonning asdf git repository..."

execute 'git -C $ASDF_PATH_DIR checkout "$(git -C $ASDF_PATH_DIR describe --abbrev=0 --tags)"' "Checking out most recent git tag..."

execute "asdf update" "Update asdf itself..."

old_plugins=(
  R
  haskell
  java
  nodejs
  python
  ruby
  rust
)

plugins=(
  elixir
  erlang
  golang
  nodejs
  python
)

for plugin in "${plugins[@]}"; do
  execute "asdf plugin-add $plugin" "Adding $plugin plugin to asdf"
done

execute "asdf plugin-update --all" "Update all plugins..."

symlink ~/.dotfiles/asdf/asdfrc ~/.asdfrc

symlink ~/.dotfiles/asdf/tool-versions ~/.tool-versions
