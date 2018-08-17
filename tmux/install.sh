#!/bin/bash

sh -c "$(curl -fsSL https://raw.githubusercontent.com/pwittchen/spotify-cli-linux/master/install.sh)"

echo "Installing Tmux..."
sudo pacman -Sy tmux -yqq

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

ln -sfT ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf
