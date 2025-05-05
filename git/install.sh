#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

#ask_for_sudo

#GIT_FUZZY_PATH_DIR="$HOME/.git-fuzzy"

#execute "git clone https://github.com/bigH/git-fuzzy.git $GIT_FUZZY_PATH_DIR" "Clonning Git Fuzzy..."

# TODO add auto update
#execute "git -C $GIT_FUZZY_PATH_DIR pull" "Updating Git Fuzzy..."

#install_package git-delta

mksymlink "$HOME/.dotfiles/git/gitconfig" "$HOME/.config/git/config"
