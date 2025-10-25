#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

mksymlink ~/.dotfiles/ulauncher/settings.json ~/.config/ulauncher/settings.json
mksymlink ~/.dotfiles/ulauncher/extensions.json ~/.config/ulauncher/extensions.json
mksymlink ~/.dotfiles/ulauncher/shortcuts.json ~/.config/ulauncher/shortcuts.json
mv ~/.dotfiles/ulauncher/themes ~/.config/ulauncher/user-themes
