#!/bin/bash

curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash

sudo apt-get remove git-lfs

unlink ~/.gitconfig
