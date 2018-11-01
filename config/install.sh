#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Symling .profile..."
ln -sfT ~/.dotfiles/config/profile ~/.profile

echo_info "Downloading fonts..."
mkdir -p ~/.fonts ~/Downloads/fonts

curl https://noto-website-2.storage.googleapis.com/pkgs/NotoColorEmoji-unhinted.zip \
  -o ~/Downloads/fonts/emoji-font.zip

wget -O ~/Downloads/fonts/Hack.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Hack.zip

wget -O ~/Downloads/fonts/fontawesome.zip \
  https://use.fontawesome.com/releases/v5.7.1/fontawesome-free-5.7.1-desktop.zip

sudo cp ~/.dotfiles/config/50-noto-color-emoji.conf /etc/fonts/conf.d/

echo_info "Downloading Wallpapers..."
mkdir -p ~/Pictures

curl -o ~/Pictures/desktop.jpg "https://images.unsplash.com/photo-1533759233673-2d30c9bc1e93"

curl -o ~/Pictures/login.jpg "https://images.unsplash.com/photo-1548354911-457c10eaf236"

sudo mv ~/Pictures/desktop.jpg /usr/share/backgrounds/i3_default_background.jpg
