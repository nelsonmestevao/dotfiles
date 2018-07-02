#!/bin/bash

source packages.sh

echo "Updating packages..."
sudo apt update -qq && sudo apt upgrade -yqq

for pkg in "${PKG[@]}"
do
  echo "Installing ${pkg}..."
  sudo apt install $pkg -yqq
done

SAVED_DIR=$PWD

cd ~/.dotfiles

dirs=$(find . -maxdepth 1 -mindepth 1 -type d -not -name '.git' -print)
for dir in $dirs
do
  echo "Installing ${dir}..."
  sh $dir/install.sh
done

cd $SAVED_DIR
