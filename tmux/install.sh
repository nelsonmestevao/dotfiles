#!/usr/bin/env sh

# sh -c "$(curl -fsSL https://raw.githubusercontent.com/pwittchen/spotify-cli-linux/master/install.sh)"

echo "Installing Tmux..."
sudo pacman -Syu tmux --needed --noconfirm

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

ln -sfT ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf

