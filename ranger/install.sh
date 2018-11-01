#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing Ranger..."
sudo pacman -S ranger --need --noconfirm

echo_info "Symlink rc.conf..."
ln -sfT ~/.dotfiles/ranger/rc.conf ~/.config/ranger/rc.conf

echo_done "Ranger configuration!"
