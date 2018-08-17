#!/usr/bin/env sh

source packages.sh

echo "Updating packages..."
pacman -U

for pkg in "${PKG[@]}"
do
  echo "Installing ${pkg}..."
  sudo pacman -Sy "$pkg" --needed --noconfirm
done

SAVED_DIR=$PWD

cd ~/.dotfiles

dirs=$(find . -maxdepth 1 -mindepth 1 -type d -not -name '.git' -print)
for dir in $dirs
do
  echo "Installing ${dir}..."
  sh "$dir"/install.sh
done

curl -o ~/Pictures/wallpaper.jpg "https://images.unsplash.com/photo-1533759233673-2d30c9bc1e93"

cd "$SAVED_DIR"

