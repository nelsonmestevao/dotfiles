#!/usr/bin/env sh

echo "Add NodeJS keys..."
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring

echo "Symling .default-npm-packages..."
ln -sfT ~/.dotfiles/ruby/default-npm-packages ~/.default-npm-packages

