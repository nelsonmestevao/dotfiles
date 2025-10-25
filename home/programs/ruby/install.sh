#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/execs.sh
. scripts/execs.sh

symlink ~/.dotfiles/ruby/default-gems ~/.default-gems

symlink ~/.dotfiles/ruby/irbrc ~/.irbrc
