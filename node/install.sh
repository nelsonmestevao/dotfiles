#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo "Add NodeJS keys..."
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring

echo "Symling .default-npm-packages..."
ln -sfT ~/.dotfiles/ruby/default-npm-packages ~/.default-npm-packages

echo_done "NodeJS configuration!"
