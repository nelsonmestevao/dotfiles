#!/usr/bin/env sh

echo "Installing Alacritty..."
git clone https://github.com/jwilm/alacritty.git make-alacritty
cd make-alacritty
cargo install cargo-deb
cargo deb --install
cd ..
rm -rf make-alacritty

ln -sfT ~/.dotfiles/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml
