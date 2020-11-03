#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Symling rebar.config..."
mkdir -p ~/.config/rebar
ln -sfT ~/.dotfiles/erlang/rebar.config ~/.config/rebar/rebar.config

echo_done "rebar3 configuration!"

