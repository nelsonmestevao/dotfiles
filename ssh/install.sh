#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

mkdir -p ~/.config/systemd/user

symlink ~/.dotfiles/ssh/sshagent.service ~/.config/systemd/user/sshagent.service

symlink ~/.dotfiles/ssh/config ~/.ssh/config
