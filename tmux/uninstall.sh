#!/bin/bash

sudo apt-get remove tmux

rm -rf ~/.tmux/plugins/tpm

unlink ~/.tmux.conf
