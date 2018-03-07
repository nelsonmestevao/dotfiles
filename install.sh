#!/bin/sh

apt install curl
apt install wget

apt install pandoc

SAVED_DIR=$PWD

cd ~/.dotfiles

dirs=$(find . -maxdepth 1 -mindepth 1 -type d -not -name '.git' -print)
for dir in $dirs
do
  echo "Installing ${dir}..."
  sh $dir/install.sh
done

cd $SAVED_DIR
