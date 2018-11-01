#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing termite..."
_install termite

echo_info "Symlink termite config"
mkdir -p ~/.config/termite
ln -sfT ~/.dotfiles/termite/config ~/.config/termite/config

echo_done "Termite configuration!"
