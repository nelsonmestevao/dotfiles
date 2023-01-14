#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

install_package fop
install_package erlang-unixodbc
install_package inotify-tools

symlink ~/.dotfiles/elixir/iex.exs ~/.iex.exs
