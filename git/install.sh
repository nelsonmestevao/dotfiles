#!/bin/bash

curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash

echo "Installing Git LFS..."
sudo apt-get install git-lfs -yqq

ln -sfT ~/.dotfiles/git/gitconfig ~/.gitconfig
