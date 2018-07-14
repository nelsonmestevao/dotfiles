#!/bin/bash

echo "Installing Redshift..."
sudo apt-get install redshift -yqq

ln -sfT ~/.dotfiles/redshift/redshift.conf ~/.config/redshift.conf

