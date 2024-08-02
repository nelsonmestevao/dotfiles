#!/usr/bin/env bash

#set -Eeuo pipefail

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh

# download_wallpapers() {
  mkdir -p ~/Pictures

  curl -o ~/Pictures/desktop.jpg "https://images.unsplash.com/photo-1533759233673-2d30c9bc1e93"

  curl -o ~/Pictures/login.jpg "https://images.unsplash.com/photo-1548354911-457c10eaf236"

  curl -o ~/Pictures/lockscreen.jpg "https://images.unsplash.com/photo-1661705969607-cde73828023d"

  # sudo cp ~/Pictures/desktop.jpg /usr/share/backgrounds/i3_default_background.jpg
# }

# ask_for_sudo

# install_package nitrogen

# mkdir -p "$HOME/.config/nitrogen"
#
# symlink "$HOME/.dotfiles/nitrogen/nitrogen.cfg" "$HOME/.config/nitrogen/nitrogen.cfg"
# symlink "$HOME/.dotfiles/nitrogen/bg-saved.cfg" "$HOME/.config/nitrogen/bg-saved.cfg"

# execute download_wallpapers "Downloading Wallpapers..."
