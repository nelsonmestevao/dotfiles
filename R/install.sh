#!/bin/sh

apt install r-base r-base-core r-base-dev -yqq

ln -sfT ~/.dotfiles/R/Rprofile ~/.Rprofile
