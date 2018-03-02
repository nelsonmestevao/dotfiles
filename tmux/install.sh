#!/bin/sh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/pwittchen/spotify-cli-linux/master/install.sh)"

apt install tmux

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

ln -sfT ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf
