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

  curl https://noto-website-2.storage.googleapis.com/pkgs/NotoColorEmoji-unhinted.zip \
    -o ~/Downloads/fonts/emoji-font.zip

  wget -O ~/Downloads/fonts/Hack.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Hack.zip

  wget -O ~/Downloads/fonts/fontawesome.zip \
    https://use.fontawesome.com/releases/v5.7.1/fontawesome-free-5.7.1-desktop.zip

  sudo cp ~/.dotfiles/config/50-noto-color-emoji.conf /etc/fonts/conf.d/

}

download_wallpapers() {
  mkdir -p ~/Pictures

  curl -o ~/Pictures/desktop.jpg "https://images.unsplash.com/photo-1533759233673-2d30c9bc1e93"

  curl -o ~/Pictures/login.jpg "https://images.unsplash.com/photo-1548354911-457c10eaf236"

  sudo mv ~/Pictures/desktop.jpg /usr/share/backgrounds/i3_default_background.jpg

}

symlink ~/.dotfiles/config/profile ~/.profile

symlink ~/.dotfiles/config/user-dirs.dirs ~/.config/user-dirs.dirs

xdg-user-dirs-update

symlink ~/.dotfiles/config/shutdown.desktop ~/.local/share/applications/shutdown.desktop

execute download_fonts "Downloading fonts..."

execute download_wallpapers "Downloading Wallpapers..."
