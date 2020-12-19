#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Symling ssh config..."
ln -sfT ~/.dotfiles/ssh/config ~/.ssh/config

echo_done "SSH configuration!"
