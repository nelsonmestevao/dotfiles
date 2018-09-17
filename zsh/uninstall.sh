#!/usr/bin/env sh

sudo pacman -Rs zsh --needed --noconfirm

rm -rf ~/.oh-my-zsh

unlink ~/.zshrc

chsh -s "$(command -v bash)"

