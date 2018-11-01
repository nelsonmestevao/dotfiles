#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing Tmux..."
_install tmux

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo_info "Symling .tmux.conf..."
ln -sfT ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf

echo_done "Tmux configuration!"
