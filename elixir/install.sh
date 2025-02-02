#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

# install_package fop
# install_package erlang-odbc
# install_package inotify-tools

symlink ~/.dotfiles/elixir/default-mix-commands ~/.default-mix-commands
symlink ~/.dotfiles/elixir/iex.exs ~/.iex.exs
