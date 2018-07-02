#!/bin/bash

sudo apt-get remove zsh

rm -rf ~/.oh-my-zsh/custom/themes/powerlevel9k

unlink ~/.zshrc

chsh -s `which bash`
