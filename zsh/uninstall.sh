#!/bin/bash

sudo apt-get remove zsh

rm -rf ~/.oh-my-zsh

unlink ~/.zshrc

chsh -s `which bash`
