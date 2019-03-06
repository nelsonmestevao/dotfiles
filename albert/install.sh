#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing albert..."
sudo yaourt -Syu albert --needed --noconfirm

echo_info "Symling albert.conf..."
mkdir -p ~/.config/albert
ln -sfT ~/.dotfiles/albert/albert.conf ~/.config/albert/albert.conf

echo_info "Symling albert engines.json..."
ln -sfT ~/.dotfiles/albert/engines.json ~/.config/albert/org.albert.extension.websearch/engines.json

echo_done "Albert configuration!"
