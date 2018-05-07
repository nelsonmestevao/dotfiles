#!/bin/bash

PKG=(
  catdoc
  catppt
  curl
  diffpdf
  odt2txt
  pandoc
  ranger
  texlive-full
  tree
  wget
  xls2csv
)

sudo apt update && sudo apt upgrade -y

for pkg in "${PKG[@]}"
do
  echo "Installing ${pkg}..."
  sudo apt install $pkg -y
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
