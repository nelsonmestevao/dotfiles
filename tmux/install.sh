#!/bin/sh

#sh -c "$(curl -fsSL https://raw.githubusercontent.com/pwittchen/spotify-cli-linux/master/install.sh)"

sudo apt install tmux

ln -sfT ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf
