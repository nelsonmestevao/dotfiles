#!/usr/bin/env sh

. packages.sh

for pkg in "${PKG[@]}"
do
  echo "Uninstalling ${pkg}..."
  sudo pacman -Rs "$pkg" --needed --noconfirm
done

SAVED_DIR=$PWD

cd ~/.dotfiles

dirs=$(find . -maxdepth 1 -mindepth 1 -type d -not -name '.git' -print)
for dir in $dirs
do
  echo "Uninstalling ${dir}..."
  sh "$dir"/uninstall.sh
done

cd "$SAVED_DIR"
