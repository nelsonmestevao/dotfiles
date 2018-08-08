#!/bin/bash

git clone git@github.com:alexanderjeurissen/ranger_devicons.git

ln -sfT ~/.dotfiles/ranger/rc.conf ~/.config/ranger/rc.conf
ln -sfT ~/.dotfiles/ranger/rifle.conf ~/.config/ranger/rifle.conf

rm -rf ranger_devicons
