#!/usr/bin/env sh

git clone --recursive https://github.com/jaagr/polybar make-polybar
mkdir polybar/build
cd polybar/build
cmake ..
sudo make install
cd ..
rm -rf make-polybar

ln -sfT ~/.dotfiles/i3/config ~/.i3/config
