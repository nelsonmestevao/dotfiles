#!/usr/bin/env sh

sudo pacman -Rs tmux --needed --noconfirm

rm -rf ~/.tmux/plugins/tpm

unlink ~/.tmux.conf
