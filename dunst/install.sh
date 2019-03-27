#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing dunst..."
_install dunst

echo_info "Symlink dunstrc..."
ln -sfT "$HOME/.dotfiles/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"

echo_done "dunstrc configuration!"
