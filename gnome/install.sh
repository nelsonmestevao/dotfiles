#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

mksymlink "$HOME/.dotfiles/gnome/extensions/pop-shell/config.json" "$HOME/.config/pop-shell/config.json"

# dconf write /org/gnome/desktop/input-sources/xkb-options "['caps:ctrl_modifier']"

# dconf write '/org/gnome/shell/extensions/pop-shell/toggle-floating' "['<Meta><Shift>Space']"

# gsettings get org.gnome.desktop.interface color-scheme

# gsettings set org.gnome.desktop.background picture-uri-dark file:///home/nelson/Pictures/desktop.jpg
# gsettings set org.gnome.desktop.background picture-uri file:///home/nelson/Pictures/login.jpg


