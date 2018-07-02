#!/bin/bash

echo "Installing Mercurial..."
sudo apt-get install mercurial -yqq

ln -sfT ~/.dotfiles/hg/hgrc ~/.hgrc
