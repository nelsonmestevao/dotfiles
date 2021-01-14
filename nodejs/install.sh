#!/usr/bin/env bash

#set -Eeuo pipefail

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

execute "bash $HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring" "Adding nodejs gpg keys..."

symlink "$HOME/.dotfiles/nodejs/default-npm-packages" "$HOME/.default-npm-packages"
