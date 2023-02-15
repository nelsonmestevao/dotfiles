#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

ask_for_sudo

download_fonts() {
  mkdir -p ~/.fonts ~/Downloads/fonts

  # remove /etc/fonts/conf.d/10-scale-bitmap-fonts.conf if having alacritty
  # emoji size problems (see https://github.com/alacritty/alacritty/issues/3791)

  curl https://noto-website-2.storage.googleapis.com/pkgs/NotoColorEmoji-unhinted.zip \
    -o ~/Downloads/fonts/emoji-font.zip

  wget -O ~/Downloads/fonts/Hack.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Hack.zip

  wget -O ~/Downloads/fonts/fontawesome.zip \
    https://use.fontawesome.com/releases/v6.2.1/fontawesome-free-6.2.1-desktop.zip

  wget -O ~/Downloads/fonts/jetbrains-mono.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/JetBrainsMono.zip

  mkdir -p /etc/fonts/conf.avail
  sudo cp ~/.dotfiles/config/66-noto-mono-compat.conf /etc/fonts/conf.avail
  sudo cp ~/.dotfiles/config/50-noto-color-emoji.conf /etc/fonts/conf.d/
}

symlink ~/.dotfiles/config/profile ~/.profile

symlink ~/.dotfiles/config/user-dirs.dirs ~/.config/user-dirs.dirs

xdg-user-dirs-update

install_package noto-color-emoji-fontconfig

symlink ~/.dotfiles/config/shutdown.desktop ~/.local/share/applications/shutdown.desktop
symlink ~/.dotfiles/config/logout.desktop ~/.local/share/applications/logout.desktop

execute download_fonts "Downloading fonts..."
