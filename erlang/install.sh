#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

ask_for_sudo

install_package fop
install_package erlang-unixodbc
install_package inotify-tools

install_rebar3() {
  wget https://s3.amazonaws.com/rebar3/rebar3
  chmod +x rebar3
  sudo mv rebar3 /usr/bin/
}

mkdir -p ~/.config/rebar
symlink ~/.dotfiles/erlang/rebar.config ~/.config/rebar/rebar.config
