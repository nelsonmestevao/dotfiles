#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

#TODO: change wget to download
install_rebar3() {
  wget https://s3.amazonaws.com/rebar3/rebar3
  chmod +x rebar3
  sudo mv rebar3 /usr/bin/
}

execute install_rebar3 "Downloading and installing rebar3..."

mkdir -p ~/.config/rebar
symlink ~/.dotfiles/erlang/rebar.config ~/.config/rebar/rebar.config
