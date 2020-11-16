#!/bin/bash

. distro.sh
. packages.sh
. helpers.sh

# Install packages in the official repositories
echo_info "Installing core packages..."
_install core

# Install packages in the AUR
echo_info "Installing aur packages..."
_install aur

_update system

_symlink

xdg-mime default pcmanfm.desktop inode/directory
betterlockscreen -u ~/Pictures/login.jpg

