#!/bin/bash

. distro.sh
. packages.sh
. helpers.sh

# Uninstall packages in the official repositories
echo_info "Uninstalling core packages..."
_uninstall core

# Uninstall packages in the AUR
echo_info "Uninstalling aur packages..."
_uninstall aur
